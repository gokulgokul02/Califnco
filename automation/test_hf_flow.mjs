import https from 'https';

const hfToken = process.env.HF_API_TOKEN;
const imgbbKey = process.env.IMGBB_API_KEY;

// Exactly matching n8n's this.helpers.httpRequest
async function n8nHttpRequest(options) {
  return new Promise((resolve, reject) => {
    let url = options.url;
    if (options.qs) {
      const q = new URLSearchParams(options.qs).toString();
      url += (url.includes('?') ? '&' : '?') + q;
    }
    const u = new URL(url);
    const req = https.request(u, {
      method: options.method || 'GET',
      headers: options.headers || {}
    }, res => {
      let chunks = [];
      res.on('data', d => chunks.push(d));
      res.on('end', () => {
        const buf = Buffer.concat(chunks);
        if (options.encoding === 'arraybuffer') {
          resolve(buf);
        } else {
          const str = buf.toString('utf8');
          if (options.json) {
            try { resolve(JSON.parse(str)); } catch(e) { resolve(str); }
          } else {
            resolve(str);
          }
        }
      });
    });
    req.on('error', reject);
    if (options.body) {
      const b = typeof options.body === 'object' ? JSON.stringify(options.body) : options.body;
      req.write(b);
    }
    req.end();
  });
}

(async () => {
  console.log('Testing n8n httpRequest simulation...');
  const jwt = await n8nHttpRequest({
    method: 'GET',
    url: 'https://huggingface.co/api/spaces/black-forest-labs/FLUX.1-schnell/jwt',
    headers: { 'Authorization': 'Bearer ' + hfToken }
  });
  const cleanJwt = String(jwt).replace(/"/g, '').trim();
  console.log('JWT received successfully');

  const sessionHash = Math.random().toString(36).substring(2);
  const joinRes = await n8nHttpRequest({
    method: 'POST',
    url: 'https://black-forest-labs-flux-1-schnell.hf.space/gradio_api/queue/join',
    headers: {
      'Authorization': 'Bearer ' + hfToken,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      data: ['Califnco water purifier commercial banner, 8k', 0, true, 1024, 1024, 4],
      event_data: null,
      fn_index: 2,
      trigger_id: null,
      session_hash: sessionHash
    }),
    json: true
  });
  console.log('Join response status: OK');

  const text = await n8nHttpRequest({
    method: 'GET',
    url: 'https://black-forest-labs-flux-1-schnell.hf.space/gradio_api/queue/data',
    qs: { session_hash: sessionHash, __sign: cleanJwt },
    headers: {
      'Authorization': 'Bearer ' + hfToken,
      'Accept': 'text/event-stream'
    }
  });

  const match = text.match(/https:\/\/[^\s"']+\/image\.webp[^\s"']*/);
  if (match) {
    console.log('SUCCESS! Hugging Face Image URL:', match[0]);

    // Download
    const imgBuf = await n8nHttpRequest({
      method: 'GET',
      url: match[0],
      encoding: 'arraybuffer'
    });
    console.log('Downloaded image size:', imgBuf.length, 'bytes');

    // Upload to ImgBB
    const postData = 'key=' + encodeURIComponent(imgbbKey) + '&image=' + encodeURIComponent(Buffer.from(imgBuf).toString('base64')) + '&name=califnco_test';
    const imgbbRes = await n8nHttpRequest({
      method: 'POST',
      url: 'https://api.imgbb.com/1/upload',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: postData,
      json: true
    });
    console.log('ImgBB Success! URL:', imgbbRes.data.url);
  } else {
    console.log('Failed:', text.slice(-200));
  }
})();
