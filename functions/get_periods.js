const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  projectId: 'locustaf-31ed2'
});

const db = getFirestore();

async function getDistinctPeriods() {
  const paystubsRef = db.collection('paystubs');
  const snapshot = await paystubsRef.get();
  
  const periods = new Set();
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.periodo) {
      periods.add(data.periodo);
    }
  });

  console.log('Distinct periods:', Array.from(periods));
}

getDistinctPeriods().catch(console.error);
