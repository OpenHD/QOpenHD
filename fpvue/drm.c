#include "drm.h"

#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>
#include <assert.h>

int modeset_open(int *out, const char *node)
{
	int fd, ret;
	uint64_t cap;

	fd = open(node, O_RDWR | O_CLOEXEC);
	if (fd < 0) {
		ret = -errno;
		fprintf(stderr, "cannot open '%s': %m\n", node);
		return ret;
	}

	ret = drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
	if (ret) {
		fprintf(stderr, "failed to set universal planes cap, %d\n", ret);
		return ret;
	}

	ret = drmSetClientCap(fd, DRM_CLIENT_CAP_ATOMIC, 1);
	if (ret) {
		fprintf(stderr, "failed to set atomic cap, %d", ret);
		return ret;
	}

	if (drmGetCap(fd, DRM_CAP_DUMB_BUFFER, &cap) < 0 || !cap) {
		fprintf(stderr, "drm device '%s' does not support dumb buffers\n",
			node);
		close(fd);
		return -EOPNOTSUPP;
	}

	if (drmGetCap(fd, DRM_CAP_CRTC_IN_VBLANK_EVENT, &cap) < 0 || !cap) {
		fprintf(stderr, "drm device '%s' does not support atomic KMS\n",
			node);
		close(fd);
		return -EOPNOTSUPP;
	}

	*out = fd;
	return 0;
}


int64_t get_property_value(int fd, drmModeObjectPropertiesPtr props,
				  const char *name)
{
	drmModePropertyPtr prop;
	uint64_t value;
	bool found;
	int j;

	found = false;
	for (j = 0; j < props->count_props && !found; j++) {
		prop = drmModeGetProperty(fd, props->props[j]);
		if (!strcmp(prop->name, name)) {
			value = props->prop_values[j];
			found = true;
		}
		drmModeFreeProperty(prop);
	}

	if (!found)
		return -1;
	return value;
}


void modeset_get_object_properties(int fd, struct drm_object *obj,
					  uint32_t type)
{
	const char *type_str;
	unsigned int i;

	obj->props = drmModeObjectGetProperties(fd, obj->id, type);
	if (!obj->props) {
		switch(type) {
			case DRM_MODE_OBJECT_CONNECTOR:
				type_str = "connector";
				break;
			case DRM_MODE_OBJECT_PLANE:
				type_str = "plane";
				break;
			case DRM_MODE_OBJECT_CRTC:
				type_str = "CRTC";
				break;
			default:
				type_str = "unknown type";
				break;
		}
		fprintf(stderr, "cannot get %s %d properties: %s\n",
			type_str, obj->id, strerror(errno));
		return;
	}

	obj->props_info = calloc(obj->props->count_props, sizeof(obj->props_info));
	for (i = 0; i < obj->props->count_props; i++)
		obj->props_info[i] = drmModeGetProperty(fd, obj->props->props[i]);
}


int set_drm_object_property(drmModeAtomicReq *req, struct drm_object *obj,
				   const char *name, uint64_t value)
{
	int i;
	uint32_t prop_id = 0;
	for (i = 0; i < obj->props->count_props; i++) {
		if (!strcmp(obj->props_info[i]->name, name)) {
			prop_id = obj->props_info[i]->prop_id;
			break;
		}
	}

	if (prop_id == 0) {
		fprintf(stderr, "no object property: %s\n", name);
		return -EINVAL;
	}

	return drmModeAtomicAddProperty(req, obj->id, prop_id, value);
}


int modeset_find_crtc(int fd, drmModeRes *res, drmModeConnector *conn, struct modeset_output *out)
{
	drmModeEncoder *enc;
	unsigned int i, j;
	uint32_t crtc;

	if (conn->encoder_id)
		enc = drmModeGetEncoder(fd, conn->encoder_id);
	else
		enc = NULL;

	if (enc) {
		if (enc->crtc_id) {
			crtc = enc->crtc_id;
			if (crtc > 0) {
				drmModeFreeEncoder(enc);
				out->crtc.id = crtc;
				out->saved_crtc = drmModeGetCrtc(fd, crtc);
				for (i = 0; i < res->count_crtcs; ++i) {
					if (res->crtcs[i] == crtc) {
						out->crtc_index = i;
						break;
					}
				}
				return 0;
			}
		}

		drmModeFreeEncoder(enc);
	}

	for (i = 0; i < conn->count_encoders; ++i) {
		enc = drmModeGetEncoder(fd, conn->encoders[i]);
		if (!enc) {
			fprintf(stderr, "cannot retrieve encoder %u:%u (%d): %m\n",
				i, conn->encoders[i], errno);
			continue;
		}

		for (j = 0; j < res->count_crtcs; ++j) {
			if (!(enc->possible_crtcs & (1 << j)))
				continue;

			crtc = res->crtcs[j];

			if (crtc > 0) {
				out->saved_crtc = drmModeGetCrtc(fd, crtc);
				fprintf(stdout, "crtc %u found for encoder %u, will need full modeset\n",
					crtc, conn->encoders[i]);;
				drmModeFreeEncoder(enc);
				out->crtc.id = crtc;
				out->crtc_index = j;
				return 0;
			}
		}

		drmModeFreeEncoder(enc);
	}

	fprintf(stderr, "cannot find suitable crtc for connector %u\n",
		conn->connector_id);
	return -ENOENT;
}

const char* drm_fourcc_to_string(uint32_t fourcc) {
    char* result = malloc(5);
    result[0] = (char)((fourcc >> 0) & 0xFF);
    result[1] = (char)((fourcc >> 8) & 0xFF);
    result[2] = (char)((fourcc >> 16) & 0xFF);
    result[3] = (char)((fourcc >> 24) & 0xFF);
    result[4] = '\0';
    return result;
}

int modeset_find_plane(int fd, struct modeset_output *out, struct drm_object *plane_out, uint32_t plane_format)
{
	drmModePlaneResPtr plane_res;
	bool found_plane = false;
	int i, ret = -EINVAL;

	plane_res = drmModeGetPlaneResources(fd);
	if (!plane_res) {
		fprintf(stderr, "drmModeGetPlaneResources failed: %s\n",
				strerror(errno));
		return -ENOENT;
	}

	for (i = 0; (i < plane_res->count_planes) && !found_plane; i++) {
		int plane_id = plane_res->planes[i];

		drmModePlanePtr plane = drmModeGetPlane(fd, plane_id);
		if (!plane) {
			fprintf(stderr, "drmModeGetPlane(%u) failed: %s\n", plane_id,
					strerror(errno));
			continue;
		}

		if (plane->possible_crtcs & (1 << out->crtc_index)) {
			for (int j=0; j<plane->count_formats; j++) {
				if (plane->formats[j] ==  plane_format) {
					found_plane = true;
				 	plane_out->id = plane_id;
				 	ret = 0;
					break;
				}
			}
		}

		drmModeFreePlane(plane);
	}

	drmModeFreePlaneResources(plane_res);

	return ret;
}


void modeset_drm_object_fini(struct drm_object *obj)
{
	for (int i = 0; i < obj->props->count_props; i++)
		drmModeFreeProperty(obj->props_info[i]);
	free(obj->props_info);
	drmModeFreeObjectProperties(obj->props);
}


int modeset_setup_objects(int fd, struct modeset_output *out)
{
	struct drm_object *connector = &out->connector;
	struct drm_object *crtc = &out->crtc;
        struct drm_object *plane_video = &out->video_plane;

	modeset_get_object_properties(fd, connector, DRM_MODE_OBJECT_CONNECTOR);
	if (!connector->props)
		goto out_conn;

	modeset_get_object_properties(fd, crtc, DRM_MODE_OBJECT_CRTC);
	if (!crtc->props)
		goto out_crtc;

        modeset_get_object_properties(fd, plane_video, DRM_MODE_OBJECT_PLANE);
        if (!plane_video->props)
                goto out_plane;
	return 0;

out_plane:
	modeset_drm_object_fini(crtc);
out_crtc:
	modeset_drm_object_fini(connector);
out_conn:
	return -ENOMEM;
}


void modeset_destroy_objects(int fd, struct modeset_output *out)
{
        modeset_drm_object_fini(&out->connector);
        modeset_drm_object_fini(&out->crtc);
        modeset_drm_object_fini(&out->video_plane);
}


int modeset_create_fb(int fd, struct modeset_buf *buf)
{
	struct drm_mode_create_dumb creq;
	struct drm_mode_destroy_dumb dreq;
	struct drm_mode_map_dumb mreq;
	int ret;
	uint32_t handles[4] = {0}, pitches[4] = {0}, offsets[4] = {0};

	memset(&creq, 0, sizeof(creq));
	creq.width = buf->width;
	creq.height = buf->height;
	creq.bpp = 32;
	ret = drmIoctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq);
	if (ret < 0) {
		fprintf(stderr, "cannot create buffer (%d): %m\n",
			errno);
		return -errno;
	}
	buf->stride = creq.pitch;
	buf->size = creq.size;
	buf->handle = creq.handle;

	handles[0] = buf->handle;
	pitches[0] = buf->stride;

	ret = drmModeAddFB2(fd, buf->width, buf->height, DRM_FORMAT_ARGB8888,
			    handles, pitches, offsets, &buf->fb, 0);
	if (ret) {
		fprintf(stderr, "cannot create framebuffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_destroy;
	}

	memset(&mreq, 0, sizeof(mreq));
	mreq.handle = buf->handle;
	ret = drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq);
	if (ret) {
		fprintf(stderr, "cannot map buffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_fb;
	}

	buf->map = mmap(0, buf->size, PROT_READ | PROT_WRITE, MAP_SHARED,
		        fd, mreq.offset);
	if (buf->map == MAP_FAILED) {
		fprintf(stderr, "cannot mmap buffer (%d): %m\n",
			errno);
		ret = -errno;
		goto err_fb;
	}

	memset(buf->map, 0, buf->size);

	return 0;

err_fb:
	drmModeRmFB(fd, buf->fb);
err_destroy:
	memset(&dreq, 0, sizeof(dreq));
	dreq.handle = buf->handle;
	drmIoctl(fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq);
	return ret;
}


void modeset_destroy_fb(int fd, struct modeset_buf *buf)
{
	struct drm_mode_destroy_dumb dreq;

	munmap(buf->map, buf->size);

	drmModeRmFB(fd, buf->fb);

	memset(&dreq, 0, sizeof(dreq));
	dreq.handle = buf->handle;
	drmIoctl(fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq);
}


int modeset_setup_framebuffers(int fd, drmModeConnector *conn, struct modeset_output *out)
{
        out->video_crtc_width = out->mode.hdisplay;
        out->video_crtc_height = out->mode.vdisplay;
        return 0;
}


void modeset_output_destroy(int fd, struct modeset_output *out)
{
	modeset_destroy_objects(fd, out);
        drmModeDestroyPropertyBlob(fd, out->mode_blob_id);
        free(out);
}

struct modeset_output *modeset_output_create(int fd, drmModeRes *res, drmModeConnector *conn, uint16_t mode_width, uint16_t mode_height, uint32_t mode_vrefresh)
{
	int ret;
	struct modeset_output *out;

	out = malloc(sizeof(*out));
	memset(out, 0, sizeof(*out));
	out->connector.id = conn->connector_id;

	if (conn->connection != DRM_MODE_CONNECTED) {
		fprintf(stderr, "ignoring unused connector %u\n",
			conn->connector_id);
		goto out_error;
	}

	if (conn->count_modes == 0) {
		fprintf(stderr, "no valid mode for connector %u\n",
			conn->connector_id);
		goto out_error;
	}

	int fc = 0;
	if (mode_width>0 && mode_height>0 && mode_vrefresh>0) {
		fc = -1;
		printf( "Available modes:\n");
		for (int i = 0; i < conn->count_modes; i++ ) {
			printf( "%d : %dx%d@%d\n",i, conn->modes[i].hdisplay, conn->modes[i].vdisplay , conn->modes[i].vrefresh );
			if (conn->modes[i].hdisplay == mode_width &&
			conn->modes[i].vdisplay == mode_height &&
			conn->modes[i].vrefresh == mode_vrefresh
			) {
				fc = i;
			}
		}
		if (fc < 0) {
			fprintf(stderr, "couldn't find a matching mode for %dx%d@%d\n", mode_width , mode_height , mode_vrefresh);
			goto out_error;
		} 
		printf( "Using screen mode %dx%d@%d\n",conn->modes[fc].hdisplay, conn->modes[fc].vdisplay , conn->modes[fc].vrefresh );
	}
	memcpy(&out->mode, &conn->modes[fc], sizeof(out->mode));
	if (drmModeCreatePropertyBlob(fd, &out->mode, sizeof(out->mode), &out->mode_blob_id) != 0) {
		fprintf(stderr, "couldn't create a blob property\n");
		goto out_error;
	}

	ret = modeset_find_crtc(fd, res, conn, out);
	if (ret) {
		fprintf(stderr, "no valid crtc for connector %u\n", conn->connector_id);
		goto out_blob;
	}

	ret = modeset_find_plane(fd, out, &out->video_plane, DRM_FORMAT_NV12);
	if (ret) {
		fprintf(stderr, "no valid video plane with format NV12 for crtc %u\n", out->crtc.id);
		goto out_blob;
	}
	fprintf(stdout, "Using plane %d (NV12) for Video\n",  out->video_plane.id);

        ret = modeset_setup_objects(fd, out);
        if (ret) {
                fprintf(stderr, "cannot get plane properties\n");
                goto out_blob;
        }

	ret = modeset_setup_framebuffers(fd, conn, out);
	if (ret) {
		fprintf(stderr, "cannot create framebuffers for connector %u\n",
			conn->connector_id);
		goto out_obj;
	}

        out->video_request = drmModeAtomicAlloc();
        assert(out->video_request);

	return out;

out_obj:
	modeset_destroy_objects(fd, out);
out_blob:
	drmModeDestroyPropertyBlob(fd, out->mode_blob_id);
out_error:
	free(out);
	return NULL;
}


int modeset_prepare(int fd, struct modeset_output *output_list, uint16_t mode_width, uint16_t mode_height, uint32_t mode_vrefresh)
{
	drmModeRes *res;
	drmModeConnector *conn;
	unsigned int i;
	struct modeset_output *out;

	res = drmModeGetResources(fd);
	if (!res) {
		fprintf(stderr, "cannot retrieve DRM resources (%d): %m\n",
			errno);
		return -errno;
	}

	for (i = 0; i < res->count_connectors; ++i) {
		conn = drmModeGetConnector(fd, res->connectors[i]);
		if (!conn) {
			fprintf(stderr, "cannot retrieve DRM connector %u:%u (%d): %m\n",
				i, res->connectors[i], errno);
			continue;
		}

		out = modeset_output_create(fd, res, conn, mode_width, mode_height, mode_vrefresh);
		drmModeFreeConnector(conn);
		if (!out)
			continue;

		*output_list = *out;
	}
	if (!output_list) {
		fprintf(stderr, "couldn't create any outputs\n");
		return -1;
	}

	drmModeFreeResources(res);
	return 0;
}

int modeset_perform_modeset(int fd, struct modeset_output *out, drmModeAtomicReq * req, struct drm_object *plane, int fb_id, int width, int height, int zpos)
{
	int ret, flags;

	ret = modeset_atomic_prepare_commit(fd, out, req, plane, fb_id, width, height, zpos);
	if (ret < 0) {
		fprintf(stderr, "prepare atomic commit failed for plane %d: %m\n", plane->id);
		return ret;
	}

	/* perform test-only atomic commit */
	flags = DRM_MODE_ATOMIC_TEST_ONLY | DRM_MODE_ATOMIC_ALLOW_MODESET;
	ret = drmModeAtomicCommit(fd, req, flags, NULL);
	if (ret < 0) {
		fprintf(stderr, "test-only atomic commit failed for plane %d: %m\n", plane->id);
		return ret;
	}

	/* initial modeset on all outputs */
    flags = DRM_MODE_ATOMIC_ALLOW_MODESET;
	ret = drmModeAtomicCommit(fd, req, flags, NULL);
	if (ret < 0)
		fprintf(stderr, "modeset atomic commit failed for plane %d: %m\n", plane->id);

	return ret;
}


int modeset_atomic_prepare_commit(int fd, struct modeset_output *out, drmModeAtomicReq *req, struct drm_object *plane, 
	int fb_id, int width, int height, int zpos)
{
	if (set_drm_object_property(req, &out->connector, "CRTC_ID", out->crtc.id) < 0)
		return -1;
	if (set_drm_object_property(req, &out->crtc, "MODE_ID", out->mode_blob_id) < 0)
		return -1;
	if (set_drm_object_property(req, &out->crtc, "ACTIVE", 1) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "FB_ID", fb_id) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "CRTC_ID", out->crtc.id) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "SRC_X", 0) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "SRC_Y", 0) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "SRC_W", width << 16) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "SRC_H", height << 16) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "CRTC_X", 0) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "CRTC_Y", 0) < 0)
		return -1;
	int crtcw = out->video_crtc_width;
	if (crtcw < width) {
		crtcw = width;
	}
	if (set_drm_object_property(req, plane, "CRTC_W", crtcw) < 0)
		return -1;
	int crtch = out->video_crtc_height;
	if (crtch < height) {
		crtch = height;
	}
	if (set_drm_object_property(req, plane, "CRTC_H", crtch) < 0)
		return -1;
	if (set_drm_object_property(req, plane, "zpos", zpos) < 0)
		return -1;

	return 0;
}


void modeset_cleanup(int fd, struct modeset_output *output_list)
{
	modeset_output_destroy(fd, output_list);
}

void
extra_modeset_set_fb(int fd, struct modeset_output *out, struct drm_object *plane, int fb_id) {
    drmModeAtomicReq *req=drmModeAtomicAlloc();
    if (set_drm_object_property(req, plane, "FB_ID", fb_id) < 0)
        return;
    int ret, flags;
    flags = DRM_MODE_ATOMIC_ALLOW_MODESET |  DRM_MODE_ATOMIC_NONBLOCK;
    ret = drmModeAtomicCommit(fd, req, flags, NULL);
    if (ret < 0)
        fprintf(stderr, "modeset atomic commit failed for plane %d: %m\n", plane->id);
    drmModeAtomicFree(req);
}
