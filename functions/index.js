const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

exports.notifyIncomingCall = onDocumentUpdated('calls/{callId}', async (event) => {
  const before = event.data?.before.data();
  const call = event.data?.after.data();
  const callId = event.params.callId;
  if (!call || !call.offer || !call.calleeId) return;
  if (before?.offer || call.status !== 'ringing') return;

  const tokenDoc = await db.collection('fcm_tokens').doc(call.calleeId).get();
  const token = tokenDoc.data()?.token;
  if (!token) return;

  await getMessaging().send({
    token,
    notification: {
      title: call.type === 'video' ? 'Panggilan video masuk' : 'Panggilan suara masuk',
      body: `${call.callerName || 'Pengguna'} sedang menelepon Anda`,
    },
    data: {
      type: 'incoming_call',
      callId,
      callerId: String(call.callerId),
      callerName: String(call.callerName || 'Pengguna'),
      callType: String(call.type || 'voice'),
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'incoming_calls',
        sound: 'default',
        defaultSound: true,
        defaultVibrateTimings: true,
        notificationCount: 1,
      },
    },
  });
});

exports.cleanupEndedCallSignaling = onDocumentUpdated('calls/{callId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after || before?.status === after.status) return;
  if (!['declined', 'disconnected', 'no_answer', 'ended'].includes(after.status)) return;

  const callRef = db.collection('calls').doc(event.params.callId);
  const batch = db.batch();
  for (const side of ['callerCandidates', 'calleeCandidates']) {
    const snapshot = await callRef.collection(side).get();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
  }
  await batch.commit();
});
