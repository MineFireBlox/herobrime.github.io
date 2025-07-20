// Supabase Setup
const supabaseUrl = 'https://ocempnupnazmapuhpkhb.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9jZW1wbnVwbmF6bWFwdWhwa2hiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mjk5NjY2NywiZXhwIjoyMDY4NTcyNjY3fQ.GlExDpy-UR0yTjyCwPBv3xshxZCmQW8OSgNgEKhJvUY';
const supabase = supabase.createClient(supabaseUrl, supabaseKey);

// DOM Elements
const recordForm = document.getElementById('recordForm');
const recordsList = document.getElementById('recordsList');
const modal = document.getElementById('filePreviewModal');
const closeBtn = document.querySelector('.close');
const iframe = document.getElementById('filePreviewFrame');

// Load records on page load
document.addEventListener('DOMContentLoaded', loadRecords);

// Form submission
recordForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const patientName = document.getElementById('patientName').value;
  const recordDate = document.getElementById('recordDate').value;
  const notes = document.getElementById('notes').value;
  const fileInput = document.getElementById('fileUpload');
  
  try {
    // Upload file if exists
    let fileUrl = null;
    if (fileInput.files[0]) {
      const fileName = `${Date.now()}_${fileInput.files[0].name}`;
      const { data, error } = await supabase.storage
        .from('medical-files')
        .upload(fileName, fileInput.files[0]);
      
      if (error) throw error;
      fileUrl = `${supabaseUrl}/storage/v1/object/public/medical-files/${data.path}`;
    }

    // Insert record
    const { error } = await supabase.from('records').insert([{
      patient_name: patientName,
      date: recordDate,
      notes: notes,
      file_url: fileUrl
    }]);
    
    if (error) throw error;
    
    // Reset form and reload records
    recordForm.reset();
    loadRecords();
    
  } catch (error) {
    console.error('Error saving record:', error);
    alert('Error saving record. Check console for details.');
  }
});

// Load all records
async function loadRecords() {
  try {
    const { data, error } = await supabase.from('records').select('*').order('date', { ascending: false });
    
    if (error) throw error;
    
    recordsList.innerHTML = data.map(record => `
      <div class="record card">
        <h3>${record.patient_name}</h3>
        <p><strong>Date:</strong> ${new Date(record.date).toLocaleDateString()}</p>
        <p><strong>Notes:</strong> ${record.notes || 'N/A'}</p>
        ${record.file_url ? `
          <button class="file-link" onclick="viewFile('${record.file_url}')">
            View Document
          </button>` : ''
        }
      </div>
    `).join('');
    
  } catch (error) {
    console.error('Error loading records:', error);
    recordsList.innerHTML = '<p>Error loading records. Please refresh.</p>';
  }
}

// File preview function
window.viewFile = function(url) {
  iframe.src = url;
  modal.style.display = 'block';
}

// Close modal
closeBtn.onclick = function() {
  modal.style.display = 'none';
  iframe.src = '';
}

// Close when clicking outside modal
window.onclick = function(event) {
  if (event.target == modal) {
    modal.style.display = 'none';
    iframe.src = '';
  }
}
