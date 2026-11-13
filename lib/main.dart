<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AI Character Swap Studio</title>
<script src="https://cdn.jsdelivr.net/npm/@vladmandic/face-api/dist/face-api.js"></script>
<style>
  *{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Tahoma,sans-serif}
  body{background:#0b0f1a;color:#e6edf7;min-height:100vh;padding:24px}
  .wrap{max-width:1100px;margin:0 auto}
  h1{font-size:28px;background:linear-gradient(90deg,#7c5cff,#00d2ff,#00ffa3);
     -webkit-background-clip:text;-webkit-text-fill-color:transparent;text-align:center;margin-bottom:8px}
  .sub{text-align:center;opacity:.65;margin-bottom:28px;font-size:14px}
  .grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}
  @media(max-width:780px){.grid{grid-template-columns:1fr}}
  .panel{background:#151b2b;border:1px solid #222c44;border-radius:16px;padding:18px}
  .panel h3{margin-bottom:12px;font-size:15px;color:#8fa3c8;text-transform:uppercase;letter-spacing:1px}
  .drop{border:2px dashed #33405e;border-radius:12px;padding:30px;text-align:center;
        cursor:pointer;transition:.2s;min-height:180px;display:flex;flex-direction:column;
        align-items:center;justify-content:center;gap:8px}
  .drop:hover{border-color:#7c5cff;background:#1a2238}
  .drop input{display:none}
  .drop p{font-size:13px;opacity:.6}
  .preview{width:100%;border-radius:12px;max-height:220px;object-fit:cover;display:none}
  .row{display:flex;gap:10px;margin-top:14px;flex-wrap:wrap}
  button{padding:11px 20px;border:none;border-radius:10px;cursor:pointer;font-weight:700;
         font-size:14px;transition:.2s}
  .btn-main{background:linear-gradient(90deg,#7c5cff,#00d2ff);color:#fff;flex:1}
  .btn-main:hover{transform:translateY(-2px);box-shadow:0 8px 22px rgba(124,92,255,.45)}
  .btn-main:disabled{opacity:.4;cursor:not-allowed;transform:none;box-shadow:none}
  .btn-ghost{background:#1e2740;color:#c6d4ec}
  canvas{width:100%;border-radius:12px;background:#000;display:none}
  .stats{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:14px}
  .stat{background:#0f1422;border:1px solid #222c44;border-radius:10px;padding:10px;text-align:center}
  .stat b{display:block;font-size:20px;color:#00ffa3}
  .stat span{font-size:11px;opacity:.6}
  .range-row{display:flex;justify-content:space-between;font-size:13px;margin-top:10px;opacity:.8}
  input[type=range]{width:100%;accent-color:#7c5cff;margin-top:6px}
  .toast{position:fixed;bottom:20px;left:50%;transform:translateX(-50%) translateY(100px);
         background:#00ffa3;color:#04110b;padding:12px 24px;border-radius:10px;font-weight:700;
         transition:.3s;z-index:99}
  .toast.show{transform:translateX(-50%) translateY(0)}
  .loading{display:none;text-align:center;padding:16px;color:#7c5cff;font-size:14px}
</style>
</head>
<body>
<div class="wrap">
  <h1>🎬 AI Character Swap Studio</h1>
  <p class="sub">تغيير الشخصيات + مونتاج تلقائي بجودة عالية</p>

  <div class="panel" style="margin-bottom:20px">
    <h3>📹 الفيديو الأصلي</h3>
    <label class="drop" id="videoDrop">
      <input type="file" id="videoInput" accept="video/*">
      <div id="videoDropContent">
        <span style="font-size:34px">🎞️</span>
        <b>اسحب فيديو هنا أو اضغط للاختيار</b>
        <p>MP4, WebM, MOV — الأفضل تحت 30 ثانية</p>
      </div>
      <video id="preview" class="preview" controls></video>
    </label>
  </div>

  <div class="grid">
    <div class="panel">
      <h3>🎭 صورة الشخصية الجديدة</h3>
      <label class="drop" id="faceDrop">
        <input type="file" id="faceInput" accept="image/*">
        <div id="faceDropContent">
          <span style="font-size:34px">🖼️</span>
          <b>ارفع صورة الوجه</b>
          <p>صورة واضحة لوجه واحد = أفضل نتيجة</p>
        </div>
        <img id="facePreview" class="preview">
      </label>
    </div>

    <div class="panel">
      <h3>⚙️ إعدادات المونتاج</h3>
      <div class="range-row"><span>قوة الدمج</span><span id="strengthVal">85%</span></div>
      <input type="range" id="strength" min="30" max="100" value="85">

      <div class="range-row"><span>نعومة الحواف</span><span id="blendVal">60%</span></div>
      <input type="range" id="blend" min="0" max="100" value="60">

      <div class="range-row"><span>حدّة التفاصيل</span><span id="sharpVal">40%</span></div>
      <input type="range" id="sharp" min="0" max="100" value="40">

      <div class="row">
        <button class="btn-ghost" onclick="resetAll()">🔄 تصفير</button>
      </div>
    </div>
  </div>

  <div class="row" style="margin-top:20px">
    <button class="btn-main" id="renderBtn" disabled onclick="renderVideo()">✨ ابدأ المونتاج التلقائي</button>
  </div>

  <div class="loading" id="loading">⏳ جاري تحليل الوجوه ودمج الشخصية...</div>

  <div class="panel" style="margin-top:20px">
    <h3>📺 النتيجة النهائية</h3>
    <canvas id="output"></canvas>
    <div class="stats">
      <div class="stat"><b id="statFrames">0</b><span>إطارات معالجة</span></div>
      <div class="stat"><b id="statFaces">0</b><span>وجوه مكتشفة</span></div>
      <div class="stat"><b id="statFps">0</b><span>FPS معالجة</span></div>
    </div>
    <div class="row" style="margin-top:14px">
      <a class="btn-main" id="downloadBtn" style="display:none;text-align:center;
         padding:12px;text-decoration:none;border-radius:10px" download="swapped.webm">⬇️ تحميل الفيديو</a>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
const $ = id => document.getElementById(id);
let videoFile, faceImage, videoEl, faceEl, faceApiReady = false;
const models = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api/model/';

// ============ تحميل النماذج ============
async function loadModels(){
  await faceapi.nets.tinyFaceDetector.loadFromUri(models);
  await faceapi.nets.faceLandmark68Net.loadFromUri(models);
  faceApiReady = true;
  toast('✅ نماذج AI جاهزة');
}
loadModels().catch(()=>toast('⚠️ تعذر تحميل النماذج — استخدم إنترنت'));

// ============ معاينة الفيديو ============
$('videoInput').addEventListener('change', e => {
  videoFile = e.target.files[0];
  if(!videoFile) return;
  const url = URL.createObjectURL(videoFile);
  const prev = $('preview');
  prev.src = url; prev.style.display = 'block';
  $('videoDropContent').style.display = 'none';
  checkReady();
});

// ============ معاينة الصورة ============
$('faceInput').addEventListener('change', e => {
  faceImage = e.target.files[0];
  if(!faceImage) return;
  const img = $('facePreview');
  img.src = URL.createObjectURL(faceImage);
  img.style.display = 'block';
  $('faceDropContent').style.display = 'none';
  checkReady();
});

// ============ تفعيل زر البدء ============
function checkReady(){
  $('renderBtn').disabled = !(videoFile && faceImage && faceApiReady);
}

// ============ المنزلقات ============
['strength','blend','sharp'].forEach(id => {
  const el = $(id);
  el.addEventListener('input', () => {
    $(id + 'Val').textContent = id === 'blend' ? el.value + '%' : el.value + '%';
  });
});

// ============ المونتاج الرئيسي ============
async function renderVideo(){
  if(!(videoFile && faceImage)) return;
  $('renderBtn').disabled = true;
  $('loading').style.display = 'block';
  $('downloadBtn').style.display = 'none';

  let stats = { frames: 0, faces: 0 };
  const startTime = performance.now();

  // تحميل الفيديو والصورة
  const video = document.createElement('video');
  video.src = URL.createObjectURL(videoFile);
  video.muted = true;
  await video.play().catch(()=>{});
  await new Promise(r => video.onloadedmetadata = r);
  video.pause();

  const faceImg = new Image();
  faceImg.src = URL.createObjectURL(faceImage);
  await new Promise(r => faceImg.onload = r);

  const W = 640;
  const H = Math.round(video.videoHeight / video.videoWidth * W) || 360;

  const canvas = $('output');
  canvas.width = W; canvas.height = H;
  canvas.style.display = 'block';
  const ctx = canvas.getContext('2d');

  // كشف وجه الصورة المصدر مرة واحدة
  const srcDetection = await faceapi.detectSingleFace(faceImg, new faceapi.TinyFaceDetectorOptions({ scoreThreshold: 0.4 }))
    .withFaceLandmarks();
  if(!srcDetection){
    toast('⚠️ لم يتم كشف وجه في الصورة — استخدم صورة أوضح');
  }
  const srcBox = srcDetection ? srcDetection.detection.box : { x: 0, y: 0, width: faceImg.width, height: faceImg.height };

  // تسجيل الفيديو الناتج
  const stream = canvas.captureStream(24);
  const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 6_000_000 });
  const chunks = [];
  recorder.ondataavailable = e => { if(e.data.size) chunks.push(e.data); };
  const done = new Promise(res => recorder.onstop = () => res(new Blob(chunks, { type:'video/webm' })));
  recorder.start();

  // معالجة الإطارات
  const fps = 24;
  const duration = video.duration || 5;
  const totalFrames = Math.floor(duration * fps);
  const strength = +$('strength').value / 100;
  const blend = +$('blend').value / 100;
  const sharp = +$('sharp').value / 100;

  for(let i = 0; i < totalFrames; i++){
    video.currentTime = i / fps;
    await new Promise(r => video.onseeked = r);
    ctx.drawImage(video, 0, 0, W, H);

    // كشف الوجه في الإطار
    const det = await faceapi.detectSingleFace(video, new faceapi.TinyFaceDetectorOptions({ scoreThreshold: 0.4 }))
      .withFaceLandmarks();

    if(det){
      stats.faces++;
      const box = det.detection.box;
      const scaleW = W / video.videoWidth;
      const scaleH = H / video.videoHeight;
      const x = box.x * scaleW, y = box.y * scaleH;
      const w = box.width * scaleW, h = box.height * scaleH;

      // رسم الوجه المصدر مع دمج ذكي
      ctx.save();
      ctx.globalAlpha = strength;
      // تحسين الحواف بقص دائري
      ctx.beginPath();
      ctx.ellipse(x + w/2, y + h/2, w*0.55*blend + w*0.45, h*0.6*blend + h*0.4, 0, 0, Math.PI*2);
      ctx.clip();
      ctx.drawImage(faceImg, srcBox.x, srcBox.y, srcBox.width, srcBox.height, x, y, w, h);
      ctx.restore();

      // تحسين الحدّة حول الوجه
      if(sharp > 0){
        ctx.save();
        ctx.globalAlpha = sharp * 0.35;
        ctx.filter = 'contrast(1.15) saturate(1.1)';
        ctx.drawImage(faceImg, srcBox.x, srcBox.y, srcBox.width, srcBox.height, x, y, w, h);
        ctx.restore();
      }
    }
    stats.frames++;
    if(i % 5 === 0){
      $('statFrames').textContent = stats.frames;
      $('statFaces').textContent = stats.faces;
    }
    // الحفاظ على التزامن
    await new Promise(r => requestAnimationFrame(r));
  }

  recorder.stop();
  const blob = await done;
  const url = URL.createObjectURL(blob);
  $('downloadBtn').href = url;
  $('downloadBtn').style.display = 'block';

  const elapsed = (performance.now() - startTime) / 1000;
  const actualFps = Math.round(stats.frames / elapsed);
  $('statFps').textContent = actualFps;

  $('loading').style.display = 'none';
  $('renderBtn').disabled = false;
  toast('🎉 اكتمل المونتاج! اضغط تحميل');
}

// ============ تصفير ============
function resetAll(){
  videoFile = faceImage = null;
  $('videoInput').value = ''; $('faceInput').value = '';
  $('preview').style.display = 'none';
  $('facePreview').style.display = 'none';
  $('videoDropContent').style.display = 'flex';
  $('faceDropContent').style.display = 'flex';
  $('output').style.display = 'none';
  $('downloadBtn').style.display = 'none';
  $('renderBtn').disabled = true;
  $('statFrames').textContent = $('statFaces').textContent = $('statFps').textContent = '0';
  toast('🔄 تم التصفير');
}

function toast(msg){
  const t = $('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2500);
}
</script>
</body>
</html>