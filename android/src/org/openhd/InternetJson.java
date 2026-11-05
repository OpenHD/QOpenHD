package org.openhd;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.os.Build;
import android.util.Log;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/** Per-request internet routing; never binds the process away from OpenHD Wi-Fi. */
public final class InternetJson {
    private InternetJson() {}

    private static Network internetNetwork(ConnectivityManager manager) {
        Network cellular = null;
        Network legacyWifi = null;
        for (Network network : manager.getAllNetworks()) {
            NetworkCapabilities caps = manager.getNetworkCapabilities(network);
            if (caps == null || !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue;
            if (Build.VERSION.SDK_INT >= 23 && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED))
                return network;
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) cellular = network;
            if (Build.VERSION.SDK_INT < 23 && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                android.net.NetworkInfo info = manager.getNetworkInfo(network);
                if (info != null && info.isConnected()) legacyWifi = network;
            }
        }
        return cellular != null ? cellular : legacyWifi;
    }

    // Called only on the ADS-B worker thread. HTTPS uses Android's TLS/trust store.
    public static String get(Context context, String address) {
        ConnectivityManager manager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        ConnectivityManager.NetworkCallback callback = null;
        HttpURLConnection connection = null;
        try {
            URL url = new URL(address);
            if (!"https".equals(url.getProtocol()) ||
                    !("api.adsb.lol".equals(url.getHost()) || "ipwho.is".equals(url.getHost())))
                throw new IllegalArgumentException("Unsupported internet service");
            Network network = internetNetwork(manager);
            if (network == null) {
                final Network[] requested = new Network[1];
                final CountDownLatch available = new CountDownLatch(1);
                callback = new ConnectivityManager.NetworkCallback() {
                    @Override public void onAvailable(Network value) { requested[0] = value; available.countDown(); }
                    @Override public void onUnavailable() { available.countDown(); }
                };
                manager.requestNetwork(new NetworkRequest.Builder()
                        .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(), callback);
                available.await(3, TimeUnit.SECONDS);
                network = requested[0];
            }
            if (network == null) throw new IllegalStateException("No internet network; enable mobile data or internet Wi-Fi");
            connection = (HttpURLConnection) network.openConnection(url);
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);
            connection.setInstanceFollowRedirects(false);
            connection.setRequestProperty("User-Agent", "QOpenHD ADS-B client");
            connection.setRequestProperty("Accept", "application/json");
            int status = connection.getResponseCode();
            if (status != 200) throw new IllegalStateException("Internet service returned HTTP " + status);
            try (InputStream input = connection.getInputStream(); ByteArrayOutputStream body = new ByteArrayOutputStream()) {
                byte[] chunk = new byte[8192];
                int count;
                while ((count = input.read(chunk)) != -1) {
                    if (body.size() + count > 2 * 1024 * 1024) throw new IllegalStateException("Internet reply too large");
                    body.write(chunk, 0, count);
                }
                return body.toString("UTF-8");
            }
        } catch (Exception error) {
            Log.w("QOpenHD-Internet", "Request failed: " + error.getClass().getSimpleName() + ": " + error.getMessage());
            return "";
        } finally {
            if (connection != null) connection.disconnect();
            if (callback != null) {
                try { manager.unregisterNetworkCallback(callback); } catch (Exception ignored) {}
            }
        }
    }
}
