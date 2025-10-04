# AgentChains.ai - AI-Powered Smart Replies

> Screenshot → AI analyzes → copied to clipboard → just paste

AgentChains.ai is an AI-powered reply assistant that transforms screenshots into smart, contextual responses in under 2 seconds using GPT-4o Vision AI.

## 🚀 Features

- **⚡ Lightning Fast**: Get perfect replies in under 2 seconds
- **🎭 Context-Aware AI**: Automatically detects app, relationship tone, and conversation context
- **📱 Works Everywhere**: WhatsApp, iMessage, Instagram, LinkedIn, Email, Slack, Discord, and any messaging app
- **🔒 Privacy-First**: Zero data retention, end-to-end encrypted, never stored
- **🎨 4 Tone Modes**: Professional, Friendly, Funny, or Flirty
- **🌍 Multi-Language Support**: Works in any language

## 🛠️ Tech Stack

- **Frontend**: Next.js 15.5.4, React 19.2.0, TypeScript
- **Styling**: Tailwind CSS 3.4.18, Framer Motion
- **Backend**: Firebase Firestore (database)
- **Email**: EmailJS (automated welcome emails)
- **Testing**: Jest, React Testing Library, Playwright
- **Deployment**: Vercel / Azure Static Web Apps

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/agentchains-website.git
cd agentchains-website

# Install dependencies
npm install

# Copy environment variables
cp .env.local.example .env.local

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the website.

## 🔧 Configuration

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Firestore Database
3. Copy your Firebase credentials to `.env.local`:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789012
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789012:web:abc123
```

See [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) for detailed instructions.

### EmailJS Setup (Welcome Emails)

1. Create a free account at [EmailJS](https://www.emailjs.com/)
2. Set up an email service (Gmail, Outlook, etc.)
3. Create a welcome email template
4. Add credentials to `.env.local`:

```env
NEXT_PUBLIC_EMAILJS_SERVICE_ID=your_service_id
NEXT_PUBLIC_EMAILJS_TEMPLATE_ID=your_template_id
NEXT_PUBLIC_EMAILJS_PUBLIC_KEY=your_public_key
```

**Email Template Variables:**
- `{{to_name}}` - User's name
- `{{to_email}}` - User's email
- `{{from_name}}` - "AgentChains.ai Team"
- `{{reply_to}}` - hello@agentchains.ai

## 📧 Welcome Email Template Example

```html
Subject: Welcome to AgentChains.ai! 🎉

Hi {{to_name}},

Thank you for joining the AgentChains.ai waitlist!

You're now part of an exclusive group getting early access to the future of AI-powered messaging.

What happens next?
✅ We'll notify you as soon as beta access is available
✅ You'll get exclusive updates on new features
✅ Priority access to launch pricing

In the meantime, follow us:
🐦 Twitter: @agentchainsai
💼 LinkedIn: AgentChains.ai

Questions? Just reply to this email!

Best regards,
The AgentChains.ai Team
https://agentchains.ai
```

## 📂 Project Structure

```
agentchains-website/
├── app/
│   ├── page.tsx           # Main homepage with waitlist form
│   ├── admin/
│   │   └── page.tsx       # Admin dashboard
│   ├── layout.tsx         # Root layout with fonts and SEO
│   └── globals.css        # Global styles and Tailwind config
├── lib/
│   └── firebase.ts        # Firebase configuration
├── public/
│   └── assets/
│       └── logos/         # Brand logos (SVG)
├── __tests__/             # Jest integration tests
├── e2e/                   # Playwright E2E tests
└── FIREBASE_SETUP.md      # Firebase setup guide
```

## 🧪 Testing

```bash
# Run integration tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run E2E tests
npm run test:e2e

# Run E2E tests with UI
npm run test:e2e:ui
```

See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for detailed testing instructions.

## 📊 Admin Dashboard

Access the admin dashboard at `/admin`:

- **URL**: http://localhost:3000/admin
- **Password**: `AgentChains2025` (change in `app/admin/page.tsx`)

### Features:
- ✅ View all waitlist submissions
- ✅ Real-time statistics
- ✅ Export to Excel (.xlsx)
- ✅ Refresh data

## 🎨 Brand Identity

- **Primary Navy**: `#04070d`
- **Accent Red**: `#ff3c00`
- **Neon Green**: `#adff00`
- **Fonts**:
  - Headings: DM Sans
  - Accent: Poppins
  - Body: Inter

## 📝 Waitlist Form Fields

The enhanced waitlist form collects:

1. **Basic Info**: Name, Email, Phone (optional)
2. **Professional Info**: Company, Role (optional)
3. **Usage**: Current ChatGPT usage
4. **Pain Points**: Messaging struggles, biggest frustration
5. **Apps**: Most-used messaging apps
6. **Engagement**: Time spent daily, willingness to pay
7. **Acquisition**: Referral source
8. **Feedback**: Feature ideas, beta tester interest

## 🚀 Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### Azure Static Web Apps

```bash
# Install Azure Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Deploy
swa deploy
```

## 📈 Performance

- **Lighthouse Score**: 95+
- **First Contentful Paint**: < 1.5s
- **Time to Interactive**: < 3.5s
- **Core Web Vitals**: All "Good"

## 🔒 Security

- **Firebase Security Rules**: Production-ready rules included
- **Environment Variables**: Never commit `.env.local`
- **Admin Password**: Change default password in production
- **Rate Limiting**: Implemented in Firestore rules
- **HTTPS Only**: Enforced in production

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

## 📞 Support

- **Email**: hello@agentchains.ai
- **Twitter**: [@agentchainsai](https://twitter.com/agentchainsai)
- **LinkedIn**: [AgentChains.ai](https://linkedin.com/company/agentchains)
- **Documentation**: [docs.agentchains.ai](https://docs.agentchains.ai)

## 🙏 Acknowledgments

- Built with [Next.js](https://nextjs.org/)
- Powered by [GPT-4o Vision AI](https://openai.com/)
- Hosted on [Vercel](https://vercel.com/)
- Database by [Firebase](https://firebase.google.com/)
- Email by [EmailJS](https://www.emailjs.com/)

---

**🤖 Built with AI by AgentChains.ai Team**

*Transforming the $1.2 trillion messaging industry, one screenshot at a time.*
