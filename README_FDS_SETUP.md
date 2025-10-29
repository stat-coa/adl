# FDS 網域部署說明

## 說明

`fds.atri.org.tw` 網域使用 **atsvp** 的程式碼和模板，不需要建立獨立的 FDS container。
只需要在 nginx 設定中讓 `fds.atri.org.tw` 指向現有的 `atsvp` container。

## 本機測試

### 快速測試（HTTP only）

```bash
# 啟動測試環境
docker-compose -f docker-compose.test.yml up -d

# 測試連線
curl http://localhost:9080/

# 或瀏覽器訪問：http://localhost:9080/
```

### 測試步驟

1. **啟動服務**
   ```bash
   docker-compose -f docker-compose.test.yml up -d
   ```

2. **檢查 containers 運行狀態**
   ```bash
   docker ps | grep -E "atsvp|nginx-test"
   ```

3. **測試 nginx 設定語法**
   ```bash
   docker exec nginx-test nginx -t
   ```

4. **測試應用回應**
   ```bash
   # 測試主頁
   curl -I http://localhost:9080/
   
   # 測試靜態檔案（如果有）
   curl -I http://localhost:9080/static/
   ```

5. **查看日誌**
   ```bash
   # 查看 atsvp 日誌
   docker logs atsvp
   
   # 查看 nginx 日誌
   docker logs nginx-test
   ```

6. **停止測試環境**
   ```bash
   docker-compose -f docker-compose.test.yml down
   ```

### 測試清單

- [ ] nginx 設定語法正確（`nginx -t` 通過）
- [ ] 可以訪問首頁（200 OK）
- [ ] 靜態檔案正常載入
- [ ] upstream 連接正常（沒有 502/504 錯誤）
- [ ] proxy_pass 設定正確（請求正確轉發到 atsvp）

## 伺服器部署步驟

### 1. 準備環境

在伺服器上找到 nginx container 的配置目錄：

```bash
# 查看 nginx-certbot 的掛載點
docker inspect nginx-certbot --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

找到類似這樣的輸出：
```
/path/to/nginx/user_conf.d -> /etc/nginx/user_conf.d
```

### 2. 確認 ATSVP Container 運行

```bash
# 確認 atsvp container 已經在運行
docker ps | grep atsvp
```

### 3. 配置 Nginx

```bash
# 1. 複製 nginx 設定檔到伺服器 nginx 的 user_conf.d 目錄
cp config/nginx/fds.conf /path/to/nginx/user_conf.d/fds.atri.org.tw.conf

# 2. 測試 nginx 配置
docker exec nginx-certbot nginx -t

# 3. 如果還沒有 SSL 憑證，先申請
docker exec nginx-certbot certbot certonly --nginx -d fds.atri.org.tw

# 4. 重新載入 nginx
docker exec nginx-certbot nginx -s reload
```

### 4. 驗證部署

```bash
# 測試連線
curl -I https://fds.atri.org.tw

# 應該會看到與 atsvp.atri.org.tw 相同的回應
```

## 架構說明

```
fds.atri.org.tw (網域)
    ↓
nginx-certbot (反向代理)
    ↓
atsvp container (實際服務)
```

`fds.atri.org.tw` 和 `atsvp.atri.org.tw` 都指向同一個 `atsvp` container，只是使用不同的網域名稱。

## 重要注意事項

### 靜態檔案路徑

`fds.conf` 使用與 `atsvp` 相同的靜態檔案路徑：
- `/app/atsvp_static_files/`

確保伺服器 nginx 的 docker-compose.yml 已經掛載：
```yaml
volumes:
  - atsvp-static-volume:/app/atsvp_static_files
```

### Network 配置

確認 atsvp container 與 nginx 在同一個 `gateway` network：
```bash
docker network inspect gateway
```

## 疑難排解

### 502 Bad Gateway

1. 檢查 atsvp container 是否運行：`docker ps | grep atsvp`
2. 檢查 network 連接：`docker network inspect gateway`
3. 確認 upstream 名稱正確：`atsvp:80`

### SSL 憑證問題

```bash
# 申請 fds.atri.org.tw 的 SSL 憑證
docker exec nginx-certbot certbot certonly --nginx -d fds.atri.org.tw
```

### 靜態檔案無法載入

檢查 nginx container 是否有掛載 atsvp 的靜態檔案 volume：
```bash
docker exec nginx-certbot ls -la /app/atsvp_static_files/
```

