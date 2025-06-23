#!/usr/bin/env node

/**
 * Test script for StreamSource Cloudflare Worker API
 * Usage: node test-api.js <worker-url> <api-key>
 */

const workerUrl = process.argv[2] || 'http://localhost:8787';
const apiKey = process.argv[3] || 'test-api-key';

async function testAPI() {
  console.log('🧪 Testing StreamSource API at:', workerUrl);
  console.log('');

  // Test 1: List active streams (public endpoint)
  console.log('1️⃣  Testing GET /api/streams (public)...');
  try {
    const response = await fetch(`${workerUrl}/api/streams`);
    const data = await response.json();
    console.log('✅ Status:', response.status);
    console.log('✅ Active streams:', data.streams?.length || 0);
    console.log('✅ Cache:', response.headers.get('X-Cache') || 'N/A');
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  console.log('');

  // Test 2: Update stream without auth (should fail)
  console.log('2️⃣  Testing PATCH without auth (should fail)...');
  try {
    const response = await fetch(`${workerUrl}/api/streams/test-id`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'ended' })
    });
    const data = await response.json();
    console.log(response.status === 401 ? '✅' : '❌', 'Status:', response.status);
    console.log('✅ Error:', data.error);
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  console.log('');

  // Test 3: Update stream with auth
  console.log('3️⃣  Testing PATCH with auth...');
  try {
    const response = await fetch(`${workerUrl}/api/streams/test-id`, {
      method: 'PATCH',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({ 
        status: 'live',
        viewerCount: 42
      })
    });
    const data = await response.json();
    console.log(response.ok ? '✅' : '⚠️ ', 'Status:', response.status);
    console.log('📝 Response:', JSON.stringify(data, null, 2));
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  console.log('');

  // Test 4: CORS headers
  console.log('4️⃣  Testing CORS headers...');
  try {
    const response = await fetch(`${workerUrl}/api/streams`, {
      method: 'OPTIONS'
    });
    console.log('✅ CORS Status:', response.status);
    console.log('✅ Allow-Origin:', response.headers.get('Access-Control-Allow-Origin'));
    console.log('✅ Allow-Methods:', response.headers.get('Access-Control-Allow-Methods'));
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  console.log('');

  console.log('✨ Tests complete!');
}

testAPI().catch(console.error);