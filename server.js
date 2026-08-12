/**
 * 简历投递管理 — 本地后端服务
 * 提供 JSON 文件持久化存储 + 静态文件服务
 * 启动后访问 http://localhost:3000 即可使用
 */
const http = require("http");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFile } = require("child_process");

const PORT = Number(process.env.PORT || 3000);
const APP_VERSION = "2.1-ocr";
// 支持开发/演示时指定独立数据文件；正常使用仍保存到程序目录的 data.json。
const DATA_FILE = process.env.RESUME_TRACKER_DATA_FILE
  ? path.resolve(process.env.RESUME_TRACKER_DATA_FILE)
  : path.join(__dirname, "data.json");
const HTML_FILE = path.join(__dirname, "resume-tracker.html");
const OCR_BINARY = path.join(__dirname, ".build", "ResumeTrackerOCR");

function runOCR(imageBuffer, extension = "png") {
  return new Promise((resolve, reject) => {
    const tempFile = path.join(os.tmpdir(), `resume-tracker-ocr-${Date.now()}-${Math.random().toString(16).slice(2)}.${extension}`);
    fs.writeFileSync(tempFile, imageBuffer);
    execFile(OCR_BINARY, [tempFile], { timeout: 30000, maxBuffer: 4 * 1024 * 1024 }, (error, stdout, stderr) => {
      fs.unlink(tempFile, () => {});
      if (error) {
        reject(new Error(stderr || error.message));
        return;
      }
      try { resolve(JSON.parse(stdout)); }
      catch (parseError) { reject(parseError); }
    });
  });
}

function getRawBody(req, limit = 12 * 1024 * 1024) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > limit) {
        reject(new Error("图片不能超过 12MB"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

// 初始化数据文件（首次运行）
if (!fs.existsSync(DATA_FILE)) {
  fs.writeFileSync(DATA_FILE, JSON.stringify([], null, 2), "utf-8");
}

function readData() {
  try {
    return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
  } catch (e) {
    return [];
  }
}

function writeData(items) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(items, null, 2), "utf-8");
}

function sendJson(res, status, data) {
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });
  res.end(JSON.stringify(data));
}

function sendStatic(res) {
  try {
    const html = fs.readFileSync(HTML_FILE, "utf-8");
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(html);
  } catch (e) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("找不到 resume-tracker.html 文件");
  }
}

function getBody(req) {
  return new Promise((resolve) => {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      try {
        resolve(JSON.parse(body));
      } catch (e) {
        resolve(null);
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = url.pathname;
  const method = req.method;

  // CORS 预检
  if (method === "OPTIONS") {
    sendJson(res, 204, {});
    return;
  }

  // API 路由
  if (pathname === "/api/items" && method === "GET") {
    const items = readData();
    sendJson(res, 200, items);
    return;
  }

  if (pathname === "/api/items" && (method === "PUT" || method === "POST")) {
    const body = await getBody(req);
    if (!Array.isArray(body)) {
      sendJson(res, 400, { error: "数据格式错误，应为数组" });
      return;
    }
    writeData(body);
    sendJson(res, 200, { ok: true, count: body.length });
    return;
  }

  if (pathname === "/api/export" && method === "GET") {
    const items = readData();
    sendJson(res, 200, { exportedAt: new Date().toISOString(), items });
    return;
  }

  if (pathname === "/api/health" && method === "GET") {
    sendJson(res, 200, { status: "ok", version: APP_VERSION, time: new Date().toISOString() });
    return;
  }

  if (pathname === "/api/ocr" && method === "POST") {
    try {
      if (!fs.existsSync(OCR_BINARY)) {
        sendJson(res, 503, { error: "OCR 组件未安装，请重新运行应用安装程序" });
        return;
      }
      const contentType = req.headers["content-type"] || "";
      if (!/^image\/(png|jpeg|jpg|heic|heif|tiff)$/i.test(contentType)) {
        sendJson(res, 415, { error: "请选择 PNG、JPG、HEIC 或 TIFF 图片" });
        return;
      }
      const extension = contentType.split("/")[1].replace("jpeg", "jpg");
      const imageBuffer = await getRawBody(req);
      if (!imageBuffer.length) {
        sendJson(res, 400, { error: "图片内容为空" });
        return;
      }
      const result = await runOCR(imageBuffer, extension);
      sendJson(res, 200, result);
    } catch (error) {
      sendJson(res, 500, { error: error.message || "文字识别失败" });
    }
    return;
  }

  // 静态文件：返回主页面
  if (pathname === "/" || pathname === "/index.html" || pathname === "/demo") {
    sendStatic(res);
    return;
  }

  // 404
  sendJson(res, 404, { error: "Not Found", path: pathname });
});

server.listen(PORT, "127.0.0.1", () => {
  console.log("");
  console.log("  ┌──────────────────────────────────────────┐");
  console.log("  │                                          │");
  console.log("  │   简历投递管理服务已启动                  │");
  console.log("  │                                          │");
  console.log(`  │   访问地址: http://localhost:${PORT}        │`);
  console.log("  │   数据文件: data.json                    │");
  console.log("  │                                          │");
  console.log("  │   按 Ctrl+C 停止服务                      │");
  console.log("  │                                          │");
  console.log("  └──────────────────────────────────────────┘");
  console.log("");

});
