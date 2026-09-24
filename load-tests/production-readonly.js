import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'https://api.jetkiz.asia';
const serverErrors = new Rate('server_errors');

export const options = {
  stages: [
    { duration: '45s', target: 20 },
    { duration: '45s', target: 50 },
    { duration: '60s', target: 100 },
    { duration: '75s', target: 200 },
    { duration: '90s', target: 350 },
    { duration: '90s', target: 500 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: [
      { threshold: 'rate<0.02', abortOnFail: true, delayAbortEval: '30s' },
    ],
    server_errors: [
      { threshold: 'rate<0.005', abortOnFail: true, delayAbortEval: '20s' },
    ],
    http_req_duration: [
      { threshold: 'p(95)<1500', abortOnFail: true, delayAbortEval: '45s' },
      'p(99)<3000',
    ],
    checks: ['rate>0.99'],
  },
  noConnectionReuse: false,
  userAgent: 'JETKIZ-production-readonly-load-test/2026-09-24',
};

function request(path, endpoint) {
  const response = http.get(`${BASE_URL}${path}`, {
    tags: { endpoint },
    timeout: '8s',
  });

  serverErrors.add(response.status === 0 || response.status >= 500, { endpoint });

  check(
    response,
    {
      [`${endpoint}: HTTP 200`]: (res) => res.status === 200,
      [`${endpoint}: under 3s`]: (res) => res.timings.duration < 3000,
    },
    { endpoint },
  );

  return response;
}

export function setup() {
  const response = request('/restaurants/public/all?random=0', 'setup_restaurants');

  if (response.status !== 200) {
    fail(`Cannot prepare load test: restaurants endpoint returned ${response.status}`);
  }

  let payload;
  try {
    payload = response.json();
  } catch (_) {
    fail('Cannot prepare load test: restaurants response is not JSON');
  }

  const items = Array.isArray(payload?.items) ? payload.items : [];
  const restaurantIds = items
    .map((item) => String(item?.id || '').trim())
    .filter((id) => id.length > 0)
    .slice(0, 12);

  if (restaurantIds.length === 0) {
    fail('Cannot prepare load test: no public restaurants returned');
  }

  return { restaurantIds };
}

export default function (data) {
  request('/home-cms/public', 'home_cms');
  sleep(1.5 + Math.random() * 1.5);

  request('/restaurants/public/list?random=0', 'restaurants_home');
  sleep(1.5 + Math.random() * 1.5);

  request('/restaurants/public/all?random=0', 'restaurants_all');
  sleep(1.5 + Math.random() * 1.5);

  const ids = data.restaurantIds;
  const restaurantId = ids[Math.floor(Math.random() * ids.length)];
  request(`/restaurants/${restaurantId}/menu`, 'restaurant_menu');

  sleep(2 + Math.random() * 2);
}
