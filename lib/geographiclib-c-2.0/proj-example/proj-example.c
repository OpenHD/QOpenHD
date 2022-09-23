/**
 * @file proj-example.c
 * @brief An example of computing geodesics with the PROJ library
 **********************************************************************/

#include <stdio.h>
#include <proj.h>
#include <geodesic.h>

int main (void) {
  /* Compute approximately equally spaced way points between LAX, 33.94N
     118.41W, and CHC, 43.49S 172.53E. */
  double a, invf;
  struct geod_geodesic g;
  struct geod_geodesicline l;
  const int n = 30;
  double lat[n+1], lon[n+1], azi[n+1];
  int i;
  {
    /* Use PROJ to get the ellipsoid parameters */
    PJ_CONTEXT* C = proj_context_create();
    char* argv[3] = {"type=crs", "proj=longlat", "ellps=WGS84"};
    PJ* P = proj_create_argv(C, 3, argv);
    if (P == 0) {
      fprintf(stderr, "Failed to create transformation object.\n");
      return 1;
    }
    proj_ellipsoid_get_parameters(C, proj_get_ellipsoid(C, P),
                                  &a, 0, 0, &invf);
    proj_destroy(P);
    proj_context_destroy(C);
  }
  /* Initialize geodesic */
  geod_init(&g, a, 1/invf);
  /* Don't need GEOD_DISTANCE_IN if using GEOD_ARCMODE */
  geod_inverseline(&l, &g, 33.94, -118.41, -43.49, 172.53,
                   GEOD_LATITUDE | GEOD_LONGITUDE | GEOD_AZIMUTH);
  printf("latitude  longitude  azimuth\n");
  for (i = 0; i <= n; ++i) {
    /* Use GEOD_LONG_UNROLL so longitude varies continuously */
    geod_genposition(&l, GEOD_ARCMODE | GEOD_LONG_UNROLL,
                     i * l.a13 / n, lat + i, lon + i, azi + i, 0, 0, 0, 0, 0);
    printf("%.5f %.5f %.5f\n", lat[i], lon[i], azi[i]);
  }
  return 0;
}
