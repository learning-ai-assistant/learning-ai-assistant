# Task 2: Frontend Optimized Dockerfile

## Описание
Внедрение современного Multi-stage Dockerfile для `web_ui_service/frontend` на базе Vite. Это устранит необходимость ручной пересборки (`npm run build`) на хосте и обеспечит быструю разработку через HMR.

## Цели
1.  **HMR в Docker:** Настройка Vite для работы через WebSocket внутри контейнера.
2.  **Оптимизация Prod:** Использование Nginx для раздачи статики с корректной обработкой роутинга (SPA).
3.  **Кэширование:** Использование слоев Docker для ускорения `npm install`.

## План реализации
1.  **Base Stage:**
    *   Образ `node:22-alpine`.
    *   Копирование `package.json` и `package-lock.json`.
    *   Запуск `npm ci`.
2.  **Dev Stage (Target):**
    *   Проброс порта 5173.
    *   Настройка `vite.config.ts` для поддержки HMR (параметры `server.watch.usePolling` и `server.hmr`).
3.  **Builder Stage:**
    *   Запуск `npm run build`.
    *   Генерация оптимизированных ассетов в папку `dist`.
4.  **Prod Stage (Target):**
    *   Образ `nginx:1.27-alpine`.
    *   Копирование ассетов из Builder в `/usr/share/nginx/html`.
    *   Добавление `nginx.conf` с правилом `try_files $uri $uri/ /index.html`.

## Критерии приемки
- [ ] При изменении React-компонента на хосте, изменения мгновенно отображаются в браузере (HMR работает).
- [ ] PROD образ содержит только Nginx и статические файлы (никаких node_modules).
- [ ] Маршрутизация (React Router) работает корректно при обновлении страницы в PROD.