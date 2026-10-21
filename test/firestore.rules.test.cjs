const { readFileSync } = require('node:fs');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
} = require('firebase/firestore');

const projectId = 'demo-creditbillsystems-rules';
const userId = 'card-owner';
const userPath = `users/${userId}`;
const cardPath = `users/${userId}/cards/card-1`;
const cardData = {
  cardName: 'Rewards',
  bankName: 'Example Bank',
  last4Digits: '1234',
  creditLimit: 2500.75,
  billingCycleDay: 18,
  gracePeriodDays: 25,
  currentBalance: 450.25,
};

let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8081,
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), userPath), { displayName: 'Owner' });
    await setDoc(doc(context.firestore(), cardPath), cardData);
  });
});

after(async () => {
  if (testEnvironment) {
    await testEnvironment.cleanup();
  }
});

test('authenticated owner can create a valid card', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();
  const newCardRef = doc(ownerDb, `${userPath}/cards/card-created-by-owner`);

  await assertSucceeds(setDoc(newCardRef, cardData));

  const created = await assertSucceeds(getDoc(newCardRef));
  if (!created.exists() || created.data().last4Digits !== cardData.last4Digits) {
    throw new Error('Owner did not create the expected card document.');
  }
});

test('authenticated owner can read and write their card', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();
  const cardRef = doc(ownerDb, cardPath);

  const snapshot = await assertSucceeds(getDoc(cardRef));
  if (!snapshot.exists() || snapshot.data().last4Digits !== '1234') {
    throw new Error('Owner did not read the expected card document.');
  }

  const cards = await assertSucceeds(
    getDocs(collection(ownerDb, `${userPath}/cards`)),
  );
  if (cards.size !== 1) {
    throw new Error('Owner did not list the expected card document.');
  }

  await assertSucceeds(setDoc(cardRef, { ...cardData, currentBalance: 100 }));
});

test('card writes require exactly the approved safe fields and types', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();

  await assertFails(
    setDoc(doc(ownerDb, cardPath), {
      ...cardData,
      fullCardNumber: '4111111111111111',
    }),
  );
  await assertFails(
    setDoc(doc(ownerDb, `${userPath}/cards/card-2`), {
      ...cardData,
      last4Digits: '4111111111111111',
    }),
  );
  await assertFails(
    setDoc(doc(ownerDb, `${userPath}/cards/card-3`), {
      ...cardData,
      billingCycleDay: '18',
    }),
  );
  const { gracePeriodDays: _, ...missingField } = cardData;
  await assertFails(setDoc(doc(ownerDb, `${userPath}/cards/card-4`), missingField));

  const invalidFieldTypes = [
    ['cardName', 123],
    ['bankName', 123],
    ['last4Digits', 1234],
    ['creditLimit', '2500.75'],
    ['billingCycleDay', '18'],
    ['gracePeriodDays', '25'],
    ['currentBalance', '450.25'],
  ];

  await Promise.all(invalidFieldTypes.map(([field, value], index) =>
    assertFails(
      setDoc(doc(ownerDb, `${userPath}/cards/invalid-type-${index}`), {
        ...cardData,
        [field]: value,
      }),
    )));
});

test('owner cannot write descendants beneath a card document', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();

  await assertFails(
    setDoc(doc(ownerDb, `${userPath}/cards/card-1/metadata/private`), {
      fullCardNumber: '4111111111111111',
    }),
  );
});

test('owner can write non-card documents beneath their user document', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();

  await assertSucceeds(
    setDoc(doc(ownerDb, `${userPath}/settings/preferences`), {
      theme: 'dark',
    }),
  );
});

test('unauthenticated caller cannot read or write a card', async () => {
  const unauthenticatedDb = testEnvironment.unauthenticatedContext().firestore();
  const cardRef = doc(unauthenticatedDb, cardPath);

  await assertFails(getDoc(cardRef));
  await assertFails(setDoc(cardRef, cardData));
  await assertFails(getDocs(collection(unauthenticatedDb, `${userPath}/cards`)));
});

test('a different authenticated UID cannot read or write another user card',
    async () => {
      const otherUserDb = testEnvironment.authenticatedContext('another-user')
          .firestore();
      const cardRef = doc(otherUserDb, cardPath);

      await assertFails(getDoc(cardRef));
      await assertFails(setDoc(cardRef, cardData));
      await assertFails(
        getDocs(collection(otherUserDb, `${userPath}/cards`)),
      );
    });

test('authenticated owner can delete their card', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();

  await assertSucceeds(deleteDoc(doc(ownerDb, cardPath)));
});

test('unauthenticated caller cannot delete a card', async () => {
  const unauthenticatedDb = testEnvironment.unauthenticatedContext().firestore();

  await assertFails(deleteDoc(doc(unauthenticatedDb, cardPath)));
});

test('a different authenticated UID cannot delete another user card',
    async () => {
      const otherUserDb = testEnvironment.authenticatedContext('another-user')
          .firestore();

      await assertFails(deleteDoc(doc(otherUserDb, cardPath)));
    });

test('authenticated owner can read and write their user document', async () => {
  const ownerDb = testEnvironment.authenticatedContext(userId).firestore();
  const userRef = doc(ownerDb, userPath);

  const snapshot = await assertSucceeds(getDoc(userRef));
  if (!snapshot.exists() || snapshot.data().displayName !== 'Owner') {
    throw new Error('Owner did not read the expected user document.');
  }

  await assertSucceeds(setDoc(userRef, { displayName: 'Updated Owner' }));
});

test('unauthenticated caller cannot read or write a user document', async () => {
  const unauthenticatedDb = testEnvironment.unauthenticatedContext().firestore();
  const userRef = doc(unauthenticatedDb, userPath);

  await assertFails(getDoc(userRef));
  await assertFails(setDoc(userRef, { displayName: 'Changed' }));
});

test('a different authenticated UID cannot read or write another user document',
    async () => {
      const otherUserDb = testEnvironment.authenticatedContext('another-user')
          .firestore();
      const userRef = doc(otherUserDb, userPath);

      await assertFails(getDoc(userRef));
      await assertFails(setDoc(userRef, { displayName: 'Changed' }));
    });
