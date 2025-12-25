import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { INDIAN_BANKS, INSURANCE_COMPANIES, BROKERS } from './data/institutionsList';

const db = admin.firestore();

/**
 * Get all institutions
 */
export const getInstitutions = functions.https.onCall(async (request) => {
    // Optional: Check auth if needed, but this might be public
    // if (!request.auth) ...

    try {
        const snapshot = await db.collection('institutions').orderBy('name').get();
        const institutions = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return { institutions };
    } catch (error) {
        console.error('Error fetching institutions:', error);
        throw new functions.https.HttpsError('internal', 'Failed to fetch institutions');
    }
});

/**
 * Seed institutions data (Admin/Dev only)
 * This uses onRequest for easy triggering via URL in browser
 */
export const seedInstitutions = functions.https.onRequest(async (req, res) => {
    try {
        const batch = db.batch();

        // Seed Banks
        INDIAN_BANKS.forEach(name => {
            const ref = db.collection('institutions').doc();
            batch.set(ref, { name, type: 'bank' });
        });

        // Seed Insurance Companies
        INSURANCE_COMPANIES.forEach(name => {
            const ref = db.collection('institutions').doc();
            batch.set(ref, { name, type: 'insurance' });
        });

        // Seed Brokers
        BROKERS.forEach(name => {
            const ref = db.collection('institutions').doc();
            batch.set(ref, { name, type: 'broker' });
        });

        await batch.commit();

        res.json({ success: true, message: `Seeded ${INDIAN_BANKS.length} banks, ${INSURANCE_COMPANIES.length} insurance companies, and ${BROKERS.length} brokers.` });
    } catch (error) {
        console.error('Error seeding institutions:', error);
        res.status(500).json({ success: false, error: 'Failed to seed institutions' });
    }
});
