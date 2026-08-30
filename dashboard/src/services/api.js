const BASE_URL = 'http://localhost:5001';

export async function fetchApi(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const defaultHeaders = {
    'Content-Type': 'application/json',
  };

  try {
    const res = await fetch(url, {
      ...options,
      headers: {
        ...defaultHeaders,
        ...options.headers,
      },
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || `API Error: ${res.status}`);
    }
    return data;
  } catch (err) {
    console.warn(`API call to ${endpoint} failed:`, err.message);
    throw err;
  }
}

// Authentication
export async function loginAdmin(username, password) {
  return fetchApi('/admin/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}

// Dashboard KPIs
export async function getDashboardStats() {
  return fetchApi('/admin/dashboard-stats');
}

// Varkaris
export async function getVarkaris(query = '', status = '') {
  const params = new URLSearchParams();
  if (query) params.append('query', query);
  if (status) params.append('status', status);
  const q = params.toString() ? `?${params.toString()}` : '';
  return fetchApi(`/varkaris${q}`);
}

// Volunteers
export async function getVolunteers() {
  return fetchApi('/volunteers');
}

export async function assignVolunteer(username, taskId = null, taskDescription = '') {
  return fetchApi(`/volunteers/${username}/assign`, {
    method: 'POST',
    body: JSON.stringify({ request_id: taskId, task_description: taskDescription }),
  });
}

// SOS & Assistance Requests
export async function getAllAssistanceRequests() {
  return fetchApi('/assistance-requests/all');
}

export async function assignSosVolunteer(requestId, volunteerUsername) {
  return fetchApi(`/assistance-requests/${requestId}/assign`, {
    method: 'POST',
    body: JSON.stringify({ volunteer_username: volunteerUsername }),
  });
}

export async function updateSosStatus(requestId, status) {
  return fetchApi(`/assistance-requests/${requestId}/status`, {
    method: 'POST',
    body: JSON.stringify({ status }),
  });
}

// Missing Persons
export async function getActiveMissingPersons() {
  return fetchApi('/missing-persons');
}

export async function getResolvedMissingPersons() {
  return fetchApi('/missing-persons/resolved');
}

export async function reportMissingPerson(formData) {
  return fetchApi('/missing-persons', {
    method: 'POST',
    body: JSON.stringify(formData),
  });
}

export async function markPersonFound(id, payload) {
  return fetchApi(`/missing-persons/${id}/found`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function verifyMissingPerson(id, resolvedBy) {
  return fetchApi(`/missing-persons/${id}/verify`, {
    method: 'POST',
    body: JSON.stringify({ resolved_by: resolvedBy }),
  });
}

// Medical Camps & Stock
export async function getMedicalCamps() {
  return fetchApi('/medical-camps');
}

export async function saveMedicalCamp(campData) {
  return fetchApi('/medical-camps', {
    method: 'POST',
    body: JSON.stringify(campData),
  });
}

export async function getMedicines() {
  return fetchApi('/medicines');
}

export async function updateMedicineStock(itemId, availableQuantity) {
  return fetchApi('/medicines', {
    method: 'POST',
    body: JSON.stringify({ item_id: itemId, available_quantity: availableQuantity }),
  });
}

// Food & Water Points
export async function getFoodWaterPoints() {
  return fetchApi('/food-water-points');
}

export async function updateFoodWaterPoint(pointId, status, availableAmount) {
  return fetchApi('/food-water-points', {
    method: 'POST',
    body: JSON.stringify({ point_id: pointId, status, available_amount: availableAmount }),
  });
}

// Weather Risk
export async function getWeatherRiskZones() {
  return fetchApi('/weather-risk');
}

// Notifications
export async function getNotifications() {
  return fetchApi('/notifications');
}

export async function markNotificationsRead(id = null) {
  return fetchApi('/notifications/mark-read', {
    method: 'POST',
    body: JSON.stringify({ id }),
  });
}

// Analytics
export async function getAnalyticsReports() {
  return fetchApi('/analytics/reports');
}

// Seed Demo Data
export async function seedDemoData() {
  return fetchApi('/admin/seed-demo-data', {
    method: 'POST',
  });
}
