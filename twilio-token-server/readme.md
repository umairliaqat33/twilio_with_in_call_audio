📘 Overview

This Node.js backend acts as the bridge between Twilio and your Flutter app.
It handles: - Generating Twilio access tokens

    - Handling voice conference calls

    - Playing audio during a live call

    - Optionally fetching call details via Twilio REST API

to set this up we required some credentials as mentioned below:

1. TWILIO_ACCOUNT_SID
2. TWILIO_AUTH_TOKEN
3. TWILIO_API_KEY
4. TWILIO_API_SECRET
5. TWILIO_APP_SID
6. FCM json

# i used ngrok to connect it with our twilio console.

=> /voice is used to route conference call.
=> /play-audio is used to play audio inside the room.

# Issue faced

I was facing issue when both users are in call and one user plays audio, other user gets disconnected.

# Solution

To solved this issue we created a conference room, where both users can join on their own instead of simple peer to peer call. With this even after playing audio, no user is thrown out of call room.

# NOTE

i did not setup a systematic way to generate and auto set tokens because that would have been unnecessary.
