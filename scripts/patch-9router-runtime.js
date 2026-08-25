#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (!key.startsWith("--")) continue;
    args[key.slice(2)] = value;
    i += 1;
  }
  return args;
}

function fail(message) {
  console.error(`[patch-runtime] ${message}`);
  process.exit(1);
}

function info(message) {
  console.log(`[patch-runtime] ${message}`);
}

function replaceSection(source, label, regex, replacement) {
  if (!regex.test(source)) {
    fail(`Khong tim thay ${label} de va runtime.`);
  }

  return source.replace(regex, replacement);
}

const args = parseArgs(process.argv);
const runtimeDir = args["runtime-dir"];

if (!runtimeDir) {
  fail("Thieu --runtime-dir.");
}

const chunkPath = path.join(runtimeDir, ".next", "server", "chunks", "9201.js");
if (!fs.existsSync(chunkPath)) {
  fail(`Khong tim thay chunk can va: ${chunkPath}`);
}

let chunkCode = fs.readFileSync(chunkPath, "utf8");

const cloudflaredModule = String.raw`3179:(a,b,c)=>{c.d(b,{Al:()=>t,F0:()=>x,es:()=>w,nN:()=>z,ss:()=>y});let d=require("fs"),e=require("path"),f=require("https"),g=require("os"),{execSync:h,spawn:i}=require("child_process"),j=c(85567),k=e.join(g.homedir(),".9router","bin"),l="cloudflared",m="win32"===g.platform(),n=m?l+".exe":l,o=e.join(k,n),p={darwin:{x64:"cloudflared-darwin-amd64.tgz",arm64:"cloudflared-darwin-amd64.tgz"},win32:{x64:"cloudflared-windows-amd64.exe"},linux:{x64:"cloudflared-linux-amd64",arm64:"cloudflared-linux-arm64"}};function q(){let a=g.platform(),b=g.arch(),c=p[a];if(!c)throw Error("Unsupported platform: "+a);let d=c[b];if(!d)throw Error("Unsupported architecture: "+b+" for platform "+a);return"https://github.com/cloudflare/cloudflared/releases/latest/download/"+d}function r(a,b){return new Promise((c,e)=>{let g=d.createWriteStream(b);f.get(a,a=>{if([301,302].includes(a.statusCode)){g.close(),d.unlinkSync(b),r(a.headers.location,b).then(c).catch(e);return}if(200!==a.statusCode){g.close(),d.unlinkSync(b),e(Error("Download failed with status "+a.statusCode));return}a.pipe(g),g.on("finish",()=>{g.close(()=>c(b))}),g.on("error",a=>{g.close(),d.unlinkSync(b),e(a)})}).on("error",a=>{g.close(),d.existsSync(b)&&d.unlinkSync(b),e(a)})})}async function t(){if(d.existsSync(k)||d.mkdirSync(k,{recursive:!0}),d.existsSync(o))return m||d.chmodSync(o,"755"),o;let a=q(),b=a.endsWith(".tgz"),c=b?e.join(k,"cloudflared.tgz"):o;return await r(a,c),b&&(h('tar -xzf "'+c+'" -C "'+k+'"',{stdio:"pipe"}),d.unlinkSync(c)),m||d.chmodSync(o,"755"),o}let u=null,v=global.__cloudflaredState??={process:null,unexpectedExitHandler:null};function w(a){v.unexpectedExitHandler=a}async function x(a){let b=await t(),c=i(b,["tunnel","run","--dns-resolver-addrs","1.1.1.1:53","--token",a],{detached:!1,stdio:["ignore","pipe","pipe"],windowsHide:m});return u=c,v.process=c,(0,j.xS)(c.pid),new Promise((a,b)=>{let d=0,e=!1,f=setTimeout(()=>{e=!0,a(c)},9e4),g=h=>{let i=h.toString().match(/Registered tunnel connection/g);i&&(d+=i.length)>=4&&!e&&(e=!0,clearTimeout(f),a(c))};c.stdout.on("data",g),c.stderr.on("data",g),c.on("error",h=>{e||(e=!0,clearTimeout(f),b(h))}),c.on("exit",h=>{u=null,v.process=null,(0,j.r4)();let i=e;if(!e){e=!0,clearTimeout(f);if(0===d){b(Error("cloudflared exited with code "+h));return}}let k=v.unexpectedExitHandler;i&&k&&k()})})}function y(){let a=v.process||u;if(a){try{a.kill()}catch(a){}u=null,v.process=null}let b=(0,j.Cr)();if(b){try{process.kill(b)}catch(a){if(m)try{h("taskkill /PID "+b+" /T /F",{stdio:"ignore"})}catch(a){}}(0,j.r4)()}if(!m)try{h("pkill -f cloudflared 2>/dev/null || true",{stdio:"ignore"})}catch(a){}}function z(){let a=(0,j.Cr)();if(!a)return!1;try{return process.kill(a,0),!0}catch(a){return!1}}}`;

const initializeModule = String.raw`19201:(a,b,c)=>{let d=c(89718),e=c(53855),f=c(3179),g=c(96182),h=require("path"),i=require("fs"),j=require("os");if(!process.env.MITM_SERVER_PATH)try{let a=h.join(process.cwd(),"src","mitm","server.js");i.existsSync(a)&&(process.env.MITM_SERVER_PATH=a)}catch{}try{(0,g.initDbHooks)(d.getSettings,d.Xx)}catch{}process.setMaxListeners(20);let k=global.__appSingleton??={initialized:!1,initPromise:null,signalHandlersRegistered:!1,watchdogInterval:null,networkMonitorInterval:null,lastNetworkFingerprint:null,lastWatchdogTick:Date.now(),lastTunnelRestartAt:0,tunnelRestartInProgress:!1},l=6e4,m=5e3,n=3e4;async function o(){if(k.initialized)return;if(k.initPromise)return k.initPromise;k.initPromise=(async()=>{try{await (0,d.bI)();let a=await (0,d.getSettings)();if(a.tunnelEnabled&&!(0,f.nN)()){console.log("[InitApp] Tunnel was enabled, auto-reconnecting...");try{await (0,e.cb)(),console.log("[InitApp] Tunnel reconnected")}catch(a){console.log("[InitApp] Tunnel reconnect failed:",a.message)}}if(!k.signalHandlersRegistered){let a=()=>{(0,f.ss)(),process.exit()};process.on("SIGINT",a),process.on("SIGTERM",a),k.signalHandlersRegistered=!0}(0,f.Al)().catch(()=>{}),p(),q(),r(),k.initialized=!0}catch(a){console.error("[InitApp] Error:",a)}finally{k.initPromise=null}})();return k.initPromise}async function p(){try{let a=await (0,d.getSettings)();if(!a.mitmEnabled||(await (0,g.getMitmStatus)()).running)return;let b=await (0,g.loadEncryptedPassword)();if(!b&&"win32"!==process.platform)return void console.log("[InitApp] MITM was enabled but no saved password found, skipping auto-start");let c=(await (0,d.getApiKeys)()).find(a=>!1!==a.isActive);if(!c)return void console.log("[InitApp] MITM auto-start skipped: no active API key");console.log("[InitApp] MITM was enabled, auto-starting..."),await (0,g.startMitm)(c.key,b||""),console.log("[InitApp] MITM auto-started")}catch(a){console.log("[InitApp] MITM auto-start failed:",a.message)}}function q(){if(k.watchdogInterval)return;k.watchdogInterval=setInterval(async()=>{try{let a=await (0,d.getSettings)();if(!a.tunnelEnabled||(0,f.nN)())return;console.log("[Watchdog] Tunnel process is down, attempting recovery..."),await (0,e.cb)(),console.log("[Watchdog] Tunnel recovered")}catch(a){console.log("[Watchdog] Recovery failed:",a.message)}},l),k.watchdogInterval.unref&&k.watchdogInterval.unref()}function r(){if(k.networkMonitorInterval)return;k.lastNetworkFingerprint=s(),k.lastWatchdogTick=Date.now(),k.networkMonitorInterval=setInterval(async()=>{try{let a=await (0,d.getSettings)();if(!a.tunnelEnabled)return;let b=Date.now(),c=b-k.lastWatchdogTick;k.lastWatchdogTick=b;let g=s(),h=g!==k.lastNetworkFingerprint,o=c>m*3;if(h&&(k.lastNetworkFingerprint=g),!h&&!o||k.tunnelRestartInProgress||b-k.lastTunnelRestartAt<n)return;let i=o&&h?"sleep/wake + network change":o?"sleep/wake":"network change";console.log("[NetworkMonitor] "+i+" detected, restarting tunnel..."),k.tunnelRestartInProgress=!0,k.lastTunnelRestartAt=b;try{(0,f.ss)(),await new Promise(a=>setTimeout(a,2e3)),await (0,e.cb)(),console.log("[NetworkMonitor] Tunnel restarted"),k.lastNetworkFingerprint=s()}finally{k.tunnelRestartInProgress=!1}}catch(a){console.log("[NetworkMonitor] Tunnel restart failed:",a.message)}},m),k.networkMonitorInterval.unref&&k.networkMonitorInterval.unref()}function s(){let a=j.networkInterfaces(),b=[];for(let[c,d]of Object.entries(a))if(d)for(let a of d)a.internal||"IPv4"!==a.family||b.push(c+":"+a.address);return b.sort().join("|")}let t=!1;(async function(){if(!t)try{await o(),t=!0}catch(a){console.error("[ServerInit] Error initializing app:",a)}return t})().catch(console.log)}`;

const tunnelManagerModule = String.raw`53855:(a,b,c)=>{c.d(b,{Jv:()=>q,Rg:()=>p,cb:()=>n});let d=require("crypto"),e=c(85567),f=c(3179),g=c(89718),h=process.env.TUNNEL_WORKER_URL||"https://tunnel.9router.com",i="abcdefghijklmnpqrstuvwxyz23456789",j=[5e3,1e4,2e4,3e4,6e4],k=j.length,l=global.__tunnelRuntime??={enablePromise:null,isReconnecting:!1};function m(){let a="";for(let b=0;b<6;b++)a+=i.charAt(Math.floor(Math.random()*i.length));return a}function o(){try{let{machineIdSync:a}=require("node-machine-id"),b=a();return d.createHash("sha256").update(b+"9router-tunnel-salt").digest("hex").substring(0,16)}catch(a){return d.randomUUID().replace(/-/g,"").substring(0,16)}}function r(a){let b="abcdefghijklmnopqrstuvwxyz0123456789",c="";for(let a=0;a<6;a++)c+=b.charAt(Math.floor(Math.random()*b.length));let e=d.createHmac("sha256","9router-tunnel-api-key-secret").update(a+c).digest("hex").slice(0,8);return"sk-"+a+"-"+c+"-"+e}async function s(a,b={}){let c=h+a,d=await fetch(c,{...b,headers:{"Content-Type":"application/json",...b.headers}});return d.json()}async function n(){if(l.enablePromise)return l.enablePromise;l.enablePromise=(async()=>{let a=(0,e.C7)();if(a&&a.tunnelUrl&&(0,f.nN)())return{success:!0,tunnelUrl:a.tunnelUrl,shortId:a.shortId,alreadyRunning:!0};(0,f.ss)();let b=o(),c=a?.shortId||m(),d=a?.apiKey||r(b);await s("/api/session/create",{method:"POST",body:JSON.stringify({apiKey:d,shortId:c})});let h=await s("/api/tunnel/create",{method:"POST",body:JSON.stringify({apiKey:d})});if(h.error)throw Error(h.error);let{token:i,hostname:j}=h;return await (0,f.F0)(i),(0,e.LZ)({shortId:c,apiKey:d,tunnelUrl:j,machineId:b}),await (0,g.Xx)({tunnelEnabled:!0,tunnelUrl:j}),(0,f.es)(()=>{l.isReconnecting||t(0)}),{success:!0,tunnelUrl:j,shortId:c}})();try{return await l.enablePromise}finally{l.enablePromise=null}}async function t(a){if(l.isReconnecting)return;l.isReconnecting=!0;let b=j[Math.min(a,j.length-1)];console.log("[Tunnel] Unexpected exit detected, reconnecting in "+b/1e3+"s (attempt "+(a+1)+")..."),await new Promise(a=>setTimeout(a,b));try{if(!(await (0,g.getSettings)()).tunnelEnabled){console.log("[Tunnel] Tunnel disabled, skipping reconnect"),l.isReconnecting=!1;return}await n(),console.log("[Tunnel] Reconnected successfully"),l.isReconnecting=!1}catch(c){console.log("[Tunnel] Reconnect attempt "+(a+1)+" failed:",c.message),l.isReconnecting=!1;let b=a+1;b<k?t(b):console.log("[Tunnel] All reconnect attempts exhausted")}}async function p(){let a=(0,e.C7)();if((0,f.ss)(),a?.apiKey)try{await s("/api/tunnel/delete",{method:"DELETE",body:JSON.stringify({apiKey:a.apiKey})})}catch(a){}return a&&(0,e.LZ)({shortId:a.shortId,apiKey:a.apiKey,machineId:a.machineId,tunnelUrl:null}),await (0,g.Xx)({tunnelEnabled:!1,tunnelUrl:""}),{success:!0}}async function q(){let a=(0,e.C7)(),b=(0,f.nN)();return{enabled:!0===(await (0,g.getSettings)()).tunnelEnabled&&b,tunnelUrl:a?.tunnelUrl||"",shortId:a?.shortId||"",running:b}}}`;

chunkCode = replaceSection(
  chunkCode,
  "module cloudflared",
  /3179:\(a,b,c\)=>\{[\s\S]*?\},19201:/,
  `${cloudflaredModule},19201:`
);

chunkCode = replaceSection(
  chunkCode,
  "module initializeApp",
  /19201:\(a,b,c\)=>\{[\s\S]*?\},53855:/,
  `${initializeModule},53855:`
);

chunkCode = replaceSection(
  chunkCode,
  "module tunnelManager",
  /53855:\(a,b,c\)=>\{[\s\S]*?\},85567:/,
  `${tunnelManagerModule},85567:`
);

fs.writeFileSync(chunkPath, chunkCode, "utf8");
info(`Da va xong ${chunkPath}`);
