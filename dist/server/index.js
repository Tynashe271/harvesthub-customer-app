export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname.startsWith("/api/")) {
      const upstream = new URL(request.url);
      upstream.protocol = "https:";
      upstream.hostname = "maphric-express-api.onrender.com";
      upstream.port = "";
      return fetch(new Request(upstream, request));
    }

    const response = await env.ASSETS.fetch(request);
    if (response.status !== 404) return response;

    if (request.method === "GET" && !url.pathname.includes(".")) {
      return env.ASSETS.fetch(new Request(new URL("/index.html", url), request));
    }

    return response;
  },
};
