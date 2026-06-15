'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "ef9e1f249ed6cb86d9cdc89f6d94e7a9",
"index_privoo_landing.html": "42062198fe693c3e9930922a48adefd8",
"version.json": "b44bab1c6f4ab03c3d4d6a3b068ce323",
"index.html": "e0b31f70ab4a7658f59742fdade065ab",
"/": "e0b31f70ab4a7658f59742fdade065ab",
"compliance.html": "4855cf9101cfcfa3783133e0c9d501f1",
"support.html": "1475399acc3bc7e76c33959c5cb1991e",
"scientific_achievements.html": "f3923f67ebc221a9c3bd8914dfd94aeb",
"main.dart.js": "da14eccd6618e407182fc77f8730e8eb",
"style_privoo_landing.css": "e8bee59477d4a7759d0d07f4287ceddb",
"privoo_features_page.html": "69b72057d27c987044c1939c8d8112cc",
"admin/support_admin.html": "6bca735bfecc519866b87a13d821036b",
"admin/login.html": "afd5907036a58446619165ee92681d99",
"admin/dashboard.html": "9ce0b65e2d23654f78cb4d8c0a25509d",
"admin/firebase.js": "22dd960368fe5d28ec01a9dfc673b5e5",
"404.html": "63ef92a05fff3178ee49ba9a365546f0",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"google5205927011087e7e.html": "deb01c64186037c9e0307931b89b940e",
"img/bot.png": "d3700b9ee9b1e4dad03a6a0eeea2d8bb",
"img/app_icon.jpeg": "5bf754953dffcefee2259962c9690d0a",
"thankyou.html": "438f21d37b17f41d30e6343100c44cf4",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "255b02b765487f3acab524fc9a8781cc",
"sitemap.xml": "693b23354349a14d684a7295c72be5c4",
"robots.txt": "531d9f23f4acdbb8532525916efe6e67",
"about_us.html": "0862885cdb73580f035ae4b812084903",
"privacy_policy.html": "f2ff1493f951871a2ee8e66963b4551a",
"assets/web/index_privoo_landing.html": "42062198fe693c3e9930922a48adefd8",
"assets/web/index.html": "3d3d1a941ff7166532e1acb830d456ab",
"assets/web/compliance.html": "4855cf9101cfcfa3783133e0c9d501f1",
"assets/web/support.html": "1475399acc3bc7e76c33959c5cb1991e",
"assets/web/scientific_achievements.html": "f3923f67ebc221a9c3bd8914dfd94aeb",
"assets/web/style_privoo_landing.css": "e8bee59477d4a7759d0d07f4287ceddb",
"assets/web/privoo_features_page.html": "69b72057d27c987044c1939c8d8112cc",
"assets/web/404.html": "63ef92a05fff3178ee49ba9a365546f0",
"assets/web/google5205927011087e7e.html": "deb01c64186037c9e0307931b89b940e",
"assets/web/img/bot.png": "d3700b9ee9b1e4dad03a6a0eeea2d8bb",
"assets/web/thankyou.html": "438f21d37b17f41d30e6343100c44cf4",
"assets/web/favicon.png": "5dcef449791fa27946b3d35ad8803796",
"assets/web/manifest.json": "255b02b765487f3acab524fc9a8781cc",
"assets/web/sitemap.xml": "693b23354349a14d684a7295c72be5c4",
"assets/web/robots.txt": "531d9f23f4acdbb8532525916efe6e67",
"assets/web/about_us.html": "0862885cdb73580f035ae4b812084903",
"assets/web/privacy_policy.html": "f2ff1493f951871a2ee8e66963b4551a",
"assets/web/download_wait.html": "bf0f38b895bc1c45a954bc6835a7ec7e",
"assets/web/privoo_pro_info.html": "ad609523542bc7a9cdf7af203162ea39",
"assets/web/terms_of_use.html": "47af2e8ca633f3be3426d73570110e71",
"assets/AssetManifest.json": "35e90f9f2900c53475ae84f5ad48eaee",
"assets/NOTICES": "64934e90870b055b528fec3dc26b57d7",
"assets/FontManifest.json": "08d5938bc18f3786cb35ff98bae33060",
"assets/AssetManifest.bin.json": "16d9e577dd3746cd152623ec6c312292",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_sound/assets/js/tau_web.js": "32cc693445f561133647b10d1b97ca07",
"assets/packages/flutter_sound/assets/js/async_processor.js": "1665e1cb34d59d2769956d2f14290274",
"assets/packages/flutter_sound_web/howler/howler.js": "3030c6101d2f8078546711db0d1a24e9",
"assets/packages/flutter_sound_web/src/flutter_sound_recorder.js": "0ec45f8c46d7ddb18691714c0c7348c8",
"assets/packages/flutter_sound_web/src/flutter_sound_player.js": "b14f8d190230d77c02ffc51ce962ce80",
"assets/packages/flutter_sound_web/src/flutter_sound_stream_processor.js": "48d52b8f36a769ea0e90cf9e58eddfa7",
"assets/packages/flutter_sound_web/src/flutter_sound.js": "3c26fcc60917c4cbaa6a30a231f7d4d8",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "7c727749c12cb24c981c22329b201d83",
"assets/fonts/MaterialIcons-Regular.otf": "c3941f5754f521fc70441df543c6ac22",
"assets/assets/images/bot.png": "d3700b9ee9b1e4dad03a6a0eeea2d8bb",
"assets/assets/images/app_icon.jpeg": "5bf754953dffcefee2259962c9690d0a",
"assets/assets/images/privoo_intro.jpeg": "0b82dfe42f8c675e2aa3afb0a6b8bd95",
"assets/assets/audio/privoo_call.wav": "75c32e77ac42f7b49ed2ad675ea9bf79",
"assets/assets/audio/privoo_message.wav": "15b0efd7b20ecc3b05183915349b9fb5",
"assets/assets/audio/privoo_notification.wav": "43d5a4f2098844e9dd4ce5e274668e38",
"assets/assets/audio/privoo_busy.wav": "3489096c95b9f3741c38d7371e4bd23e",
"assets/assets/audio/privoo_ringing.wav": "2fea428d0d9ee6b7fb9f46476bfb993f",
"assets/assets/audio/privoo_offline.wav": "801b494dee28fa395a2b4614e48f8d11",
"assets/assets/fonts/Cairo-Regular.ttf": "45aaa2b5f9de1d61c2d3fe1f40107ac8",
"assets/assets/fonts/Cairo-Bold.ttf": "2bbe2088a8d666fa99b80554fdc6effd",
"download_wait.html": "bf0f38b895bc1c45a954bc6835a7ec7e",
"privoo_pro_info.html": "ad609523542bc7a9cdf7af203162ea39",
"terms_of_use.html": "47af2e8ca633f3be3426d73570110e71",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
