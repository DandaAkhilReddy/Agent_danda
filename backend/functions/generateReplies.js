const { app } = require('@azure/functions');
const { AzureOpenAI } = require('@azure/openai');
const { DefaultAzureCredential } = require('@azure/identity');

/**
 * ReplyCopilot - Generate AI Reply Suggestions
 *
 * Privacy-First Design:
 * - No screenshot storage (memory only)
 * - No text retention
 * - Logs metadata only
 * - Immediate buffer cleanup
 */

// Initialize Azure OpenAI client (uses managed identity or env vars)
const endpoint = process.env.OPENAI_ENDPOINT;
const apiKey = process.env.OPENAI_API_KEY;
const deploymentName = process.env.OPENAI_DEPLOYMENT || 'gpt-4o-vision';

const client = new AzureOpenAI({
  endpoint,
  apiKey,
  apiVersion: '2024-08-01-preview'
});

// Tone-specific system prompts
const TONE_PROMPTS = {
  professional: `You are a professional communication assistant. Generate polite, clear, and business-appropriate replies.
    Use proper grammar, avoid slang, and maintain a respectful tone. Keep replies concise (2-3 sentences max).`,

  friendly: `You are a friendly communication assistant. Generate warm, casual replies with appropriate emojis.
    Use conversational language, be helpful and approachable. Keep replies short and natural (2-3 sentences).`,

  funny: `You are a witty communication assistant. Generate clever, humorous replies with light jokes or puns.
    Keep it appropriate and fun, use emojis when fitting. Stay brief and entertaining (2-3 sentences).`,

  flirty: `You are a charming communication assistant. Generate playful, subtly flirty replies with emojis.
    Be tasteful and fun, not overly forward. Keep it light and engaging (2-3 sentences).`
};

// Platform-specific guidelines
const PLATFORM_STYLES = {
  whatsapp: 'Use emojis frequently, casual language, keep very short',
  imessage: 'Natural iOS messaging style, some emojis, conversational',
  instagram: 'Trendy, emoji-heavy, very casual, keep ultra-short',
  outlook: 'Professional email style, minimal emojis, proper formatting',
  slack: 'Professional but casual, use slack conventions like :emoji:',
  teams: 'Business professional, clear and direct, minimal emojis'
};

/**
 * Main function: Generate reply suggestions from screenshot
 */
app.http('generateReplies', {
  methods: ['POST'],
  authLevel: 'function',
  handler: async (request, context) => {
    const startTime = Date.now();

    try {
      // Parse request body
      const body = await request.json();
      const {
        image,           // base64-encoded screenshot
        platform = 'whatsapp',
        tone = 'friendly',
        userId,
        metadata = {}
      } = body;

      // Validate input
      if (!image) {
        return {
          status: 400,
          jsonBody: { error: 'Missing required field: image' }
        };
      }

      if (!['professional', 'friendly', 'funny', 'flirty'].includes(tone)) {
        return {
          status: 400,
          jsonBody: { error: 'Invalid tone. Must be: professional, friendly, funny, or flirty' }
        };
      }

      context.log(`[${userId || 'anonymous'}] Processing reply request - Platform: ${platform}, Tone: ${tone}`);

      // Build prompt
      const systemPrompt = buildSystemPrompt(tone, platform);
      const userPrompt = buildUserPrompt();

      // Convert base64 to data URL (kept in memory only)
      const imageDataUrl = image.startsWith('data:') ? image : `data:image/jpeg;base64,${image}`;

      // Call Azure OpenAI Vision API
      const response = await client.chat.completions.create({
        model: deploymentName,
        messages: [
          {
            role: 'system',
            content: systemPrompt
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: userPrompt
              },
              {
                type: 'image_url',
                image_url: { url: imageDataUrl }
              }
            ]
          }
        ],
        max_tokens: 200,
        temperature: 0.7,
        n: 1
      });

      // Parse suggestions from response
      const rawContent = response.choices[0]?.message?.content || '';
      const suggestions = parseSuggestions(rawContent);

      // Calculate processing time
      const processingTime = Date.now() - startTime;

      // Log metadata only (NO screenshot, NO text content)
      context.log(`[${userId || 'anonymous'}] Generated ${suggestions.length} suggestions in ${processingTime}ms`);

      // Return response
      return {
        status: 200,
        jsonBody: {
          success: true,
          suggestions,
          platform,
          tone,
          processingTime,
          timestamp: new Date().toISOString()
        },
        headers: {
          'Content-Type': 'application/json',
          'X-Processing-Time': `${processingTime}ms`
        }
      };

    } catch (error) {
      context.error('Error generating replies:', error);

      return {
        status: 500,
        jsonBody: {
          success: false,
          error: 'Failed to generate replies',
          message: error.message
        }
      };
    }

    // Note: No cleanup needed - JavaScript GC handles memory
    // Image data was never persisted to disk/database
  }
});

/**
 * Build system prompt based on tone and platform
 */
function buildSystemPrompt(tone, platform) {
  const tonePrompt = TONE_PROMPTS[tone] || TONE_PROMPTS.friendly;
  const platformStyle = PLATFORM_STYLES[platform] || PLATFORM_STYLES.whatsapp;

  return `${tonePrompt}

Platform: ${platform} - ${platformStyle}

CRITICAL RULES:
1. Read the entire chat conversation from the screenshot
2. Generate 3-5 distinct reply options (as a bulleted list)
3. Each reply must be 2-3 sentences maximum
4. Match the ${platform} messaging style
5. NEVER quote or repeat text from the screenshot
6. NEVER store or remember any content from the image
7. Focus on the most recent message and provide contextual replies
8. Ensure replies are natural and conversational
9. Use appropriate emojis for the platform and tone

Output format:
- Reply option 1
- Reply option 2
- Reply option 3
(etc.)`;
}

/**
 * Build user prompt
 */
function buildUserPrompt() {
  return `Please read this chat screenshot and generate 3-5 appropriate reply suggestions based on the system instructions. Focus on replying to the most recent message.`;
}

/**
 * Parse suggestions from AI response
 * Expects bulleted list format: - suggestion\n- suggestion
 */
function parseSuggestions(rawContent) {
  // Split by newlines and extract bullet points
  const lines = rawContent.split('\n')
    .map(line => line.trim())
    .filter(line => line.startsWith('-') || line.startsWith('•') || line.startsWith('*'));

  // Clean up bullets
  const suggestions = lines.map(line =>
    line.replace(/^[-•*]\s*/, '').trim()
  ).filter(s => s.length > 0);

  // If no bullets found, try to split by periods or newlines as fallback
  if (suggestions.length === 0) {
    return rawContent
      .split(/[.\n]/)
      .map(s => s.trim())
      .filter(s => s.length > 10 && s.length < 200)
      .slice(0, 5);
  }

  return suggestions.slice(0, 5); // Max 5 suggestions
}

/**
 * Health check endpoint
 */
app.http('health', {
  methods: ['GET'],
  authLevel: 'anonymous',
  handler: async (request, context) => {
    return {
      status: 200,
      jsonBody: {
        status: 'healthy',
        service: 'replycopilot-backend',
        version: '1.0.0',
        timestamp: new Date().toISOString()
      }
    };
  }
});

module.exports = { app };
