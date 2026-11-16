const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const OpenAI = require("openai");

const openAiApiKey = defineSecret("OPENAI_API_KEY");

exports.chatWithOpenAI = onCall(
  {
    region: "us-central1",
    secrets: [openAiApiKey],
  },
  async (request) => {
    const message = request.data.message;

    if (!message || typeof message !== "string") {
      throw new HttpsError("invalid-argument", "Message is required.");
    }

    const client = new OpenAI({
      apiKey: openAiApiKey.value(),
    });

    const response = await client.responses.create({
      model: "gpt-4.1-mini",
      input: message,
    });

    return {
      reply: response.output_text,
    };
  }
);
