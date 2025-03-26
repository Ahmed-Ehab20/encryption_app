from re import sub

ALPHABET = "abcdefghijklmnopqrstuvwxyz"
frequency = {
    "a": 8.2, "b": 1.5, "c": 2.8, "d": 4.3, "e": 13,
    "f": 2.2, "g": 2, "h": 6.1, "i": 7, "j": 0.15,
    "k": 0.77, "l": 4, "m": 2.4, "n": 6.7, "o": 7.5,
    "p": 1.9, "q": 0.095, "r": 6, "s": 6.3, "t": 9.1,
    "u": 2.8, "v": 0.98, "w": 2.4, "x": 0.15, "y": 2, 
    "z": 0.074
}

def kasiski(message):
    message = sub(r'[^a-z]+', "", message.lower())
    return findKey(message, findKeyLength(findRepeats(message)))

def findRepeats(message):
    sequences = {}
    for seqLength in range(2, 5):  # Testing with n-grams of length 2 to 4
        for seqBegin in range(len(message) - seqLength + 1):
            seq = message[seqBegin: seqBegin + seqLength]
            for i in range(seqBegin + seqLength, len(message) - seqLength + 1):
                if message[i:i + seqLength] == seq:
                    if seq not in sequences:
                        sequences[seq] = []
                    sequences[seq].append(i - seqBegin)
    return sequences

def findKeyLength(sequences):
    potentialKeyAccuracy = {}
    for i in range(2, 17):  # Potential key lengths
        counter = 0
        secondaryCounter = 0
        for item in sequences:
            for num in sequences[item]:
                secondaryCounter += 1
                if num % i == 0:
                    counter += 1
        if secondaryCounter == 0:
            raise Exception("No repetitions found; try with a longer ciphertext!")
        counter /= secondaryCounter
        potentialKeyAccuracy[i] = counter

    potentialKeys = [item for item in potentialKeyAccuracy if potentialKeyAccuracy[item] > 0.80]
    if not potentialKeys:
        raise Exception("No suitable key lengths found.")
    return max(potentialKeys)

def findKey(message, keyLength):
    key = ""
    for i in range(keyLength):
        positionalDict = {letter: {char: 0 for char in ALPHABET} for letter in ALPHABET}
        scoredDict = {letter: 0 for letter in ALPHABET}

        for letter in ALPHABET:
            index = i
            while index < len(message):
                row = ALPHABET.find(message[index])
                column = ALPHABET.find(letter)
                if row != -1 and column != -1:
                    positionalDict[letter][ALPHABET[(row - column) % 26]] += 1
                index += keyLength

            for char in ALPHABET:
                scoredDict[letter] += positionalDict[letter][char] * frequency[char]

        letter = max(scoredDict, key=scoredDict.get)
        key += letter
    
    return key

# Testing with a longer Vigenère cipher
message = "Lxfopv ef rnhrz qg gztfncigz."  # Replace with example Vigenère ciphertext
key = kasiski(message)
print("\nThe key is probably: \n" + key + "\n")

# Assumed existence of "vigenere" function for decryption
# Uncomment the next line on a correct vigenere implementation
# print("Therefore, the deciphered text is probably:\n" + vigenere(message, key, "decrypt") + "\n")