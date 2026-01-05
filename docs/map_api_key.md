# Map widget API key setup (Mapbox)

The Map widget supports Mapbox tiles when you provide an access token. Follow these steps to create a token and enable the Mapbox provider:

1. **Create or sign in to a Mapbox account**
   - Go to <https://account.mapbox.com> and sign in (or create a free account).

2. **Create or copy an access token**
   - Open the **Tokens** tab in your account dashboard.
   - Use the **Default public token** or click **Create a token** and keep the default scopes (for typical use, the defaults with `styles:read` are sufficient).
   - Copy the token; it begins with `pk.`.

3. **Add the token in QOpenHD**
   - Open the Map widget settings (gear icon) and pick **Mapbox (API key)** as the provider.
   - Paste the token into the **Map API key** field.
   - Close and reopen the map if prompted; the widget will rebuild the map using your token.

4. **Keep your key safe**
   - Do not publish your token in screenshots or videos.
   - If a token is exposed, revoke it from the Mapbox **Tokens** page and create a new one.

Once the token is saved in settings, the Mapbox map should load without the “API key required” notice.
