'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'

export default function Home() {
  const [scrolled, setScrolled] = useState(false)
  const [selectedTone, setSelectedTone] = useState('friendly')
  const [selectedPlatform, setSelectedPlatform] = useState('whatsapp')
  const [loading, setLoading] = useState(false)
  const [replies, setReplies] = useState<string[]>([])
  const [repliesCount, setRepliesCount] = useState(0)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const mockReplies = {
    friendly: {
      whatsapp: [
        "Hey! Coffee sounds awesome! 😊 How about Saturday afternoon?",
        "I'd love to! ☕ Let's do it! Saturday work for you?",
        "Count me in! 🙌 When and where?",
      ],
      imessage: [
        "That sounds like so much fun! 🎉 I'll be there!",
        "Yay! Count me in! What should I bring?",
        "Perfect timing! I'm definitely coming! 😊",
      ],
    },
    professional: {
      whatsapp: [
        "Thank you for the invitation. Saturday afternoon works well for me.",
        "I'd be happy to join you. Please let me know the time and location.",
        "Sounds good. I'm available Saturday. What time were you thinking?",
      ],
    },
  }

  const generateReplies = () => {
    setLoading(true)
    setReplies([])

    setTimeout(() => {
      const toneReplies = (mockReplies as any)[selectedTone]?.[selectedPlatform] || mockReplies.friendly.whatsapp
      setReplies(toneReplies)
      setRepliesCount(prev => prev + toneReplies.length)
      setLoading(false)
    }, 1500)
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Navbar */}
      <nav className={`fixed top-0 w-full z-50 transition-all duration-300 ${
        scrolled ? 'bg-white/95 backdrop-blur-lg shadow-lg' : 'bg-transparent'
      }`}>
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-4xl">🤖</span>
              <span className={`text-2xl font-black ${scrolled ? 'text-gray-900' : 'text-white'}`}>
                ReplyCopilot
              </span>
            </div>

            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-primary transition`}>
                Features
              </a>
              <a href="#demo" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-primary transition`}>
                Demo
              </a>
              <a href="#pricing" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-primary transition`}>
                Pricing
              </a>
            </div>

            <div className="flex items-center gap-4">
              <button className="px-6 py-3 rounded-xl font-bold text-white bg-gradient-to-r from-primary to-secondary hover:shadow-2xl hover:-translate-y-1 transition-all duration-300">
                Get Started Free
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-primary via-secondary to-accent">
        {/* Animated Background Blobs */}
        <div className="absolute inset-0 overflow-hidden">
          <motion.div
            className="absolute w-96 h-96 bg-pink-400/30 rounded-full blur-3xl"
            animate={{
              x: [0, 100, 0],
              y: [0, -100, 0],
            }}
            transition={{ duration: 20, repeat: Infinity }}
            style={{ top: '-10%', left: '-10%' }}
          />
          <motion.div
            className="absolute w-80 h-80 bg-blue-400/30 rounded-full blur-3xl"
            animate={{
              x: [0, -80, 0],
              y: [0, 80, 0],
            }}
            transition={{ duration: 15, repeat: Infinity }}
            style={{ bottom: '-10%', right: '-10%' }}
          />
          <motion.div
            className="absolute w-72 h-72 bg-purple-400/30 rounded-full blur-3xl"
            animate={{
              x: [0, 60, 0],
              y: [0, 60, 0],
            }}
            transition={{ duration: 18, repeat: Infinity }}
            style={{ top: '50%', left: '50%' }}
          />
        </div>

        <div className="relative z-10 max-w-6xl mx-auto px-6 text-center text-white">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white/20 backdrop-blur-sm border border-white/30 mb-8"
          >
            <span className="text-xl">💎</span>
            <span className="text-sm font-semibold">Powered by GPT-4o Vision • Trillion Dollar Messaging Industry • Privacy-First</span>
          </motion.div>

          <motion.h1
            className="text-7xl md:text-8xl font-black mb-6 leading-tight"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
          >
            Never Struggle with<br />
            <span className="bg-gradient-to-r from-white to-pink-200 bg-clip-text text-transparent">
              Messaging Again
            </span>
          </motion.h1>

          <motion.p
            className="text-xl md:text-2xl mb-12 max-w-3xl mx-auto leading-relaxed opacity-95"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            AI-powered reply assistant that transforms screenshots into smart, contextual responses in under 2 seconds.
            Works with WhatsApp, iMessage, Instagram, and any messaging app.
          </motion.p>

          <motion.div
            className="flex flex-col sm:flex-row items-center justify-center gap-6 mb-16"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
          >
            <a
              href="#demo"
              className="px-10 py-5 rounded-2xl font-bold text-lg bg-white text-primary hover:shadow-2xl hover:-translate-y-2 transition-all duration-300 inline-flex items-center gap-3"
            >
              <span>Try Free Demo</span>
              <span className="text-2xl">→</span>
            </a>
            <button className="px-10 py-5 rounded-2xl font-bold text-lg bg-white/20 backdrop-blur-sm border-2 border-white/40 text-white hover:bg-white/30 hover:-translate-y-2 transition-all duration-300 inline-flex items-center gap-3">
              <span className="text-xl">▶</span>
              <span>Watch Demo</span>
            </button>
          </motion.div>

          <motion.div
            className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            {[
              { number: '< 2s', label: 'Response Time' },
              { number: '4', label: 'Tone Modes' },
              { number: '6+', label: 'Platforms' },
              { number: '100%', label: 'Private' },
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <div className="text-5xl font-black mb-2">{stat.number}</div>
                <div className="text-sm opacity-90">{stat.label}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Market Opportunity */}
      <section className="py-20 bg-white border-b-2 border-gray-100">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-gradient-to-r from-primary/10 to-secondary/10 border-2 border-primary/20 mb-8">
              <span className="text-4xl">💎</span>
              <span className="text-2xl font-black bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
                Trillion Dollar Industry
              </span>
            </div>
            <h3 className="text-4xl md:text-5xl font-black mb-6 text-gray-900">
              The Future of Communication is AI-Powered
            </h3>
            <p className="text-xl text-gray-600 max-w-4xl mx-auto leading-relaxed">
              With <strong>5+ billion</strong> people using messaging apps daily, the communication industry generates
              <strong className="text-primary"> over $1 trillion</strong> in value annually. ReplyCopilot leverages
              enterprise-grade GPT-4o Vision AI to revolutionize how professionals communicate across all platforms.
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-16 max-w-5xl mx-auto">
              {[
                { number: '$1T+', label: 'Industry Value' },
                { number: '5B+', label: 'Daily Users' },
                { number: '100B+', label: 'Messages/Day' },
                { number: '30min', label: 'Saved Daily' },
              ].map((stat, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, scale: 0.8 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                  className="text-center p-6 rounded-2xl bg-gradient-to-br from-gray-50 to-gray-100"
                >
                  <div className="text-5xl font-black bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent mb-2">
                    {stat.number}
                  </div>
                  <div className="text-sm font-semibold text-gray-600">{stat.label}</div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-32 bg-gray-50">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-6xl font-black mb-4 text-gray-900">Enterprise-Grade AI Technology</h2>
            <p className="text-xl text-gray-600">Built for the trillion-dollar communication industry</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              { icon: '🎭', title: '4 Intelligent Tone Modes', desc: 'Professional, Friendly, Funny, or Flirty - adapt to any situation' },
              { icon: '⚡', title: 'Lightning Fast', desc: 'Get 3-5 smart suggestions in under 2 seconds' },
              { icon: '🔒', title: 'Privacy-First', desc: 'Zero data retention. Never stored, never logged' },
              { icon: '📱', title: 'Works Everywhere', desc: 'WhatsApp, iMessage, Instagram, Slack, and more' },
              { icon: '🤖', title: 'GPT-4o Vision AI', desc: 'Latest AI model with deep context understanding' },
              { icon: '🎨', title: 'Context-Aware', desc: 'Reads entire conversation flow for perfect replies' },
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                viewport={{ once: true }}
                whileHover={{ y: -10, scale: 1.02 }}
                className="p-8 rounded-3xl bg-gradient-to-br from-gray-100 to-gray-200 hover:shadow-2xl transition-all duration-300 border-2 border-transparent hover:border-primary"
              >
                <div className="text-6xl mb-4">{feature.icon}</div>
                <h3 className="text-2xl font-bold mb-3 text-gray-900">{feature.title}</h3>
                <p className="text-gray-600 leading-relaxed">{feature.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Interactive Demo Section */}
      <section id="demo" className="py-32 bg-gradient-to-br from-primary via-secondary to-accent">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16 text-white">
            <h2 className="text-6xl font-black mb-4">Try It Yourself!</h2>
            <p className="text-xl opacity-95">Interactive demo with mock data - No sign-up required</p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            {/* Demo Controls */}
            <div className="bg-white rounded-3xl p-8 shadow-2xl">
              <h3 className="text-3xl font-bold mb-6 text-gray-900">Choose Your Style</h3>

              <div className="mb-8">
                <label className="block text-sm font-bold mb-3 text-gray-700">🎭 Tone</label>
                <div className="grid grid-cols-2 gap-3">
                  {['friendly', 'professional', 'funny', 'flirty'].map((tone) => (
                    <button
                      key={tone}
                      onClick={() => setSelectedTone(tone)}
                      className={`px-6 py-4 rounded-xl font-bold transition-all duration-300 ${
                        selectedTone === tone
                          ? 'bg-gradient-to-r from-primary to-secondary text-white shadow-lg scale-105'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      {tone.charAt(0).toUpperCase() + tone.slice(1)}
                    </button>
                  ))}
                </div>
              </div>

              <div className="mb-8">
                <label className="block text-sm font-bold mb-3 text-gray-700">📱 Platform</label>
                <select
                  value={selectedPlatform}
                  onChange={(e) => setSelectedPlatform(e.target.value)}
                  className="w-full px-6 py-4 rounded-xl border-2 border-gray-200 font-semibold bg-white hover:border-primary transition"
                >
                  <option value="whatsapp">WhatsApp</option>
                  <option value="imessage">iMessage</option>
                  <option value="instagram">Instagram</option>
                  <option value="slack">Slack</option>
                </select>
              </div>

              <button
                onClick={generateReplies}
                disabled={loading}
                className="w-full px-8 py-5 rounded-2xl font-bold text-lg text-white bg-gradient-to-r from-primary to-secondary hover:shadow-2xl hover:-translate-y-1 transition-all duration-300 disabled:opacity-50"
              >
                {loading ? '✨ Generating...' : '✨ Generate Smart Replies'}
              </button>

              <div className="mt-6 text-center text-sm text-gray-500">
                💡 <strong>{repliesCount}</strong> replies generated in this demo!
              </div>
            </div>

            {/* Results */}
            <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-8 border-2 border-white/20">
              <h3 className="text-3xl font-bold mb-6 text-white">Your Smart Replies</h3>

              {loading && (
                <div className="flex flex-col items-center justify-center py-16">
                  <div className="w-16 h-16 border-4 border-white/30 border-t-white rounded-full animate-spin mb-4"></div>
                  <p className="text-white text-lg">AI is analyzing...</p>
                </div>
              )}

              {!loading && replies.length === 0 && (
                <div className="text-center py-16 text-white/70">
                  <div className="text-6xl mb-4">🤖</div>
                  <p className="text-lg">Click "Generate" to see AI magic!</p>
                </div>
              )}

              {!loading && replies.length > 0 && (
                <div className="space-y-4">
                  {replies.map((reply, i) => (
                    <motion.div
                      key={i}
                      initial={{ opacity: 0, x: -30 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: i * 0.1 }}
                      onClick={() => navigator.clipboard.writeText(reply)}
                      className="p-5 rounded-2xl bg-white/90 backdrop-blur-sm cursor-pointer hover:bg-white hover:scale-105 transition-all duration-300 group"
                    >
                      <p className="text-gray-900 leading-relaxed">{reply}</p>
                      <span className="float-right text-2xl opacity-50 group-hover:opacity-100 transition">📋</span>
                    </motion.div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-32 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-6xl font-black mb-4 text-gray-900">Simple Pricing</h2>
            <p className="text-xl text-gray-600">Start free, upgrade when you need more</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                name: 'Free',
                price: '$0',
                features: ['20 replies/day', '4 tone modes', 'All platforms', 'Privacy-first'],
                cta: 'Get Started',
                popular: false
              },
              {
                name: 'Pro',
                price: '$9.99',
                features: ['Unlimited replies', '4 tone modes', 'All platforms', 'Priority support'],
                cta: 'Start Pro Trial',
                popular: true
              },
              {
                name: 'Enterprise',
                price: 'Custom',
                features: ['Everything in Pro', 'Team management', 'API access', 'Dedicated support'],
                cta: 'Contact Sales',
                popular: false
              },
            ].map((plan, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                viewport={{ once: true }}
                className={`relative p-8 rounded-3xl transition-all duration-300 ${
                  plan.popular
                    ? 'bg-gradient-to-br from-primary to-secondary text-white scale-105 shadow-2xl'
                    : 'bg-gray-50 hover:shadow-xl'
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-6 py-2 rounded-full bg-pink-500 text-white font-bold text-sm">
                    MOST POPULAR
                  </div>
                )}
                <h3 className="text-2xl font-bold mb-4">{plan.name}</h3>
                <div className="text-6xl font-black mb-6">{plan.price}</div>
                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature, j) => (
                    <li key={j} className="flex items-start gap-2">
                      <span className="text-xl">✓</span>
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
                <button className={`w-full px-8 py-4 rounded-xl font-bold text-lg transition-all duration-300 ${
                  plan.popular
                    ? 'bg-white text-primary hover:shadow-xl hover:-translate-y-1'
                    : 'bg-gradient-to-r from-primary to-secondary text-white hover:shadow-xl hover:-translate-y-1'
                }`}>
                  {plan.cta}
                </button>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-32 bg-gradient-to-br from-primary via-secondary to-accent text-white text-center">
        <div className="max-w-4xl mx-auto px-6">
          <h2 className="text-6xl font-black mb-6">Ready to Transform Your Messaging?</h2>
          <p className="text-2xl mb-12 opacity-95">Join thousands saving 30+ minutes daily with AI-powered replies</p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
            <button className="px-12 py-6 rounded-2xl font-bold text-lg bg-white text-primary hover:shadow-2xl hover:-translate-y-2 transition-all duration-300">
              Start Free Trial
            </button>
            <button className="px-12 py-6 rounded-2xl font-bold text-lg bg-white/20 backdrop-blur-sm border-2 border-white/40 hover:bg-white/30 hover:-translate-y-2 transition-all duration-300">
              Watch Demo
            </button>
          </div>
          <p className="mt-8 text-lg opacity-90">🎉 No credit card required • 20 free replies daily</p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-16">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <div className="flex items-center justify-center gap-3 mb-6">
            <span className="text-5xl">🤖</span>
            <span className="text-3xl font-black">ReplyCopilot</span>
          </div>
          <p className="text-gray-400 mb-8">AI-powered smart replies for any messaging app</p>
          <div className="text-gray-500">
            © 2025 ReplyCopilot. Built with ❤️ and GPT-4o
          </div>
        </div>
      </footer>
    </div>
  )
}
