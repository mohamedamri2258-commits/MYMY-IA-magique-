self.addEventListener('install', (e) => {
      console.log('[Service Worker] Installed');
      });

      self.addEventListener('fetch', (e) => {
        // تفعيل الاستجابة السريعة للملفات
          e.respondWith(
              caches.match(e.request).then((response) => {
                    return response || fetch(e.request);
                        })
                          );
                          });
                          
})