require("dotenv").config();
const twilio = require("twilio");
const express = require("express");
const AccessToken = twilio.jwt.AccessToken;
const VoiceGrant = AccessToken.VoiceGrant;

const voiceGrant = new VoiceGrant({
  outgoingApplicationSid: process.env.TWIML_APP_SID,
  incomingAllow: true,
  pushCredentialSid: process.env.TWILIO_PUSH_CREDENTIAL_SID,
});

const token = new AccessToken(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_API_KEY,
  process.env.TWILIO_API_SECRET,
  { identity: "BobId" }
);
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);
token.addGrant(voiceGrant);

console.log("Access Token:");
console.log(token.toJwt());

const app = express();
const port = process.env.PORT || 3000;

app.use(express.urlencoded({ extended: false }));
app.use(express.json());
app.post("/voice", (req, res, next) => {
  try {
    const VoiceResponse = require("twilio").twiml.VoiceResponse;
    console.log("call data: " + req.body);

    const twiml = new VoiceResponse();
    const dial = twiml.dial();

    dial.conference("mainRoom", {
      startConferenceOnEnter: true,
      endConferenceOnExit: true,
    });

    console.log("[INFO] Joined conference: mainRoom");
    res.type("text/xml");
    res.send(twiml.toString());
  } catch (error) {
    console.error("[ERROR] /voice failed:", error);
    next(error);
  }
});

app.post("/play-audio", async (req, res) => {
  try {
    const audioUrl = req.body.audioUrl || "https://your-domain.com/audio.mp3";

    const conferenceName = "mainRoom";

    const conferences = await twilioClient.conferences.list({
      friendlyName: conferenceName,
      status: "in-progress",
      limit: 1,
    });

    if (conferences.length === 0) {
      return res.status(404).json({ message: "No active conference found." });
    }

    const conferenceSid = conferences[0].sid;
    console.log(`[INFO] Found conference SID: ${conferenceSid}`);

    const participants = await twilioClient
      .conferences(conferenceSid)
      .participants.list();

    for (const p of participants) {
      console.log(`[INFO] Playing audio for participant: ${p.callSid}`);
      await twilioClient.calls(p.callSid).update({
        twiml: `<Response><Play>${audioUrl}</Play></Response>`,
      });
    }

    res.json({
      success: true,
      message: "Audio played for all participants.",
    });
  } catch (error) {
    console.error("[ERROR] /play-audio failed:", error);
    res.status(500).json({ error: error.message });
  }
});

app.use((err, req, res, next) => {
  console.error("[GLOBAL ERROR]", err);
  res.status(500).json({
    message: "An unexpected error occurred on the server.",
    error: err.message,
  });
});

app.listen(port, () => {
  console.log(`🚀 Server is running on port ${port}`);
});
