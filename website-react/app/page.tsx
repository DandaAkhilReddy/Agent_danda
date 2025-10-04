'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { collection, addDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '../lib/firebase'
import emailjs from '@emailjs/browser'

export default function Home() {
  const [scrolled, setScrolled] = useState(false)
  const [selectedTone, setSelectedTone] = useState('professional')
  const [loading, setLoading] = useState(false)
  const [replies, setReplies] = useState<string[]>([])

  // Waitlist Form State
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    company: '',
    role: '',
    usingChatGPT: '',
    struggles: [] as string[],
    strugglesOther: '',
    biggestPainPoint: '',
    apps: [] as string[],
    appsOther: '',
    ideas: '',
    timeSpent: '',
    willingToPay: '',
    referralSource: '',
    betaTester: false
  })
  const [formSubmitted, setFormSubmitted] = useState(false)
  const [formSubmitting, setFormSubmitting] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const mockReplies = {
    professional: [
      "Thank you for reaching out. I'd be happy to discuss this further. When would be a good time for you?",
      "I appreciate you bringing this to my attention. Let me review and get back to you by end of day.",
      "That sounds like a great opportunity. I'm very interested in learning more about this."
    ],
    friendly: [
      "Hey! That sounds awesome! 😊 I'd love to chat about this more!",
      "Thanks for thinking of me! When do you want to catch up?",
      "This is so exciting! Let's make it happen! 🙌"
    ],
    funny: [
      "I'm in! Just tell me where and when, and I'll bring the snacks! 🍿",
      "Say no more! My schedule just cleared itself like magic ✨",
      "You had me at 'hey' 😄 Count me in!"
    ],
    flirty: [
      "I was hoping you'd ask 😊 Would love to!",
      "You know just what to say to make my day ✨",
      "I'd love that! Can't wait to see you 💫"
    ]
  }

  const generateReplies = () => {
    setLoading(true)
    setReplies([])

    setTimeout(() => {
      const toneReplies = (mockReplies as any)[selectedTone] || mockReplies.professional
      setReplies(toneReplies)
      setLoading(false)
    }, 1500)
  }

  const handleCheckboxChange = (field: 'struggles' | 'apps', value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: prev[field].includes(value)
        ? prev[field].filter(item => item !== value)
        : [...prev[field], value]
    }))
  }

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setFormSubmitting(true)

    try {
      // Save to Firestore
      await addDoc(collection(db, 'waitlist-submissions'), {
        ...formData,
        submittedAt: new Date().toISOString(),
        timestamp: serverTimestamp()
      })

      console.log('Form submitted successfully to Firebase:', formData)

      // Send welcome email via EmailJS
      try {
        const serviceId = process.env.NEXT_PUBLIC_EMAILJS_SERVICE_ID || ''
        const templateId = process.env.NEXT_PUBLIC_EMAILJS_TEMPLATE_ID || ''
        const publicKey = process.env.NEXT_PUBLIC_EMAILJS_PUBLIC_KEY || ''

        if (serviceId && templateId && publicKey) {
          await emailjs.send(
            serviceId,
            templateId,
            {
              to_name: formData.name,
              to_email: formData.email,
              from_name: 'AgentChains.ai Team',
              reply_to: 'hello@agentchains.ai',
            },
            publicKey
          )
          console.log('Welcome email sent successfully!')
        } else {
          console.warn('EmailJS not configured - skipping welcome email')
        }
      } catch (emailError) {
        console.error('Error sending welcome email:', emailError)
        // Don't fail the whole form submission if email fails
      }

      setFormSubmitted(true)

      // Reset form after 5 seconds
      setTimeout(() => {
        setFormSubmitted(false)
        setFormData({
          name: '',
          email: '',
          phone: '',
          company: '',
          role: '',
          usingChatGPT: '',
          struggles: [],
          strugglesOther: '',
          biggestPainPoint: '',
          apps: [],
          appsOther: '',
          ideas: '',
          timeSpent: '',
          willingToPay: '',
          referralSource: '',
          betaTester: false
        })
      }, 5000)
    } catch (error) {
      console.error('Error saving to Firebase:', error)
      alert('Error submitting form. Please try again.')
    } finally {
      setFormSubmitting(false)
    }
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
              <img
                src="/assets/logos/logo-light.svg"
                alt="AgentChains.ai"
                className={`h-8 transition-opacity ${scrolled ? 'hidden' : 'block'}`}
              />
              <img
                src="/assets/logos/logo-dark.svg"
                alt="AgentChains.ai"
                className={`h-8 transition-opacity ${scrolled ? 'block' : 'hidden'}`}
              />
            </div>

            <div className="hidden md:flex items-center gap-8">
              <a href="#how-it-works" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-accent transition`}>
                How It Works
              </a>
              <a href="#demo" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-accent transition`}>
                Demo
              </a>
              <a href="#pricing" className={`font-semibold ${scrolled ? 'text-gray-700' : 'text-white/90'} hover:text-accent transition`}>
                Pricing
              </a>
            </div>

            <div className="flex items-center gap-4">
              <a href="#waitlist" className="px-6 py-3 rounded-xl font-bold text-white bg-gradient-to-r from-accent to-neon hover:shadow-2xl hover:-translate-y-1 transition-all duration-300 glow-neon">
                Join Waitlist
              </a>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden gradient-bg-hero">
        {/* Animated Background Effects */}
        <div className="absolute inset-0 overflow-hidden">
          <motion.div
            className="absolute w-96 h-96 bg-accent/20 rounded-full blur-3xl"
            animate={{
              x: [0, 100, 0],
              y: [0, -100, 0],
            }}
            transition={{ duration: 20, repeat: Infinity }}
            style={{ top: '-10%', left: '-10%' }}
          />
          <motion.div
            className="absolute w-80 h-80 bg-neon/20 rounded-full blur-3xl"
            animate={{
              x: [0, -80, 0],
              y: [0, 80, 0],
            }}
            transition={{ duration: 15, repeat: Infinity }}
            style={{ bottom: '-10%', right: '-10%' }}
          />
        </div>

        <div className="relative z-10 max-w-6xl mx-auto px-6 text-center text-white">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full glass border border-white/30 mb-8"
          >
            <span className="text-xl">📱</span>
            <span className="text-sm font-semibold">iOS app: coming soon</span>
          </motion.div>

          <motion.h1
            className="text-5xl md:text-7xl font-black mb-6 leading-tight font-heading"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
          >
            Screenshot → AI analyzes →<br />
            <span className="text-gradient">
              copied to clipboard
            </span> → just paste
          </motion.h1>

          <motion.p
            className="text-xl md:text-2xl mb-12 max-w-3xl mx-auto leading-relaxed opacity-95"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            Reply to anything by taking a screenshot. AgentChains.ai reads the screen, crafts the answer, and puts it on your clipboard instantly.
          </motion.p>

          <motion.div
            className="flex flex-col sm:flex-row items-center justify-center gap-6 mb-16"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
          >
            <a
              href="#waitlist"
              className="px-10 py-5 rounded-2xl font-bold text-lg bg-white text-primary hover:shadow-2xl hover:-translate-y-2 transition-all duration-300 inline-flex items-center gap-3"
            >
              <span>Get Early Access</span>
              <span className="text-2xl">→</span>
            </a>
            <button className="px-10 py-5 rounded-2xl font-bold text-lg glass hover:bg-white/30 hover:-translate-y-2 transition-all duration-300 inline-flex items-center gap-3">
              <span className="text-xl">▶</span>
              <span>Watch 30-sec Demo</span>
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
              { number: '∞', label: 'Works Everywhere' },
              { number: '100%', label: 'Private & Secure' },
              { number: '$1T', label: 'Industry' },
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <div className="text-5xl font-black mb-2 font-accent">{stat.number}</div>
                <div className="text-sm opacity-90">{stat.label}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* How It Works - 3 Steps */}
      <section id="how-it-works" className="py-32 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 text-primary font-heading">How It Works</h2>
            <p className="text-xl text-gray-600 font-accent">Three simple steps. No apps to open. No typing.</p>
          </div>

          <div className="grid md:grid-cols-3 gap-12">
            {[
              {
                step: '1',
                icon: '📸',
                title: 'Screenshot Any Conversation',
                desc: 'Just take a screenshot like you normally do. Works with WhatsApp, iMessage, Instagram, LinkedIn, Email—literally any app on your phone.',
                highlight: 'Don\'t even think about what app it is'
              },
              {
                step: '2',
                icon: '🤖',
                title: 'AI Understands Everything',
                desc: 'GPT-4o Vision analyzes the conversation context, app background, relationship tone, and urgency to generate the perfect reply.',
                highlight: 'Professional for LinkedIn, casual for WhatsApp'
              },
              {
                step: '3',
                icon: '✨',
                title: 'Reply Ready to Paste',
                desc: 'Perfect reply automatically copied to your clipboard. Just open your app and paste. That\'s it. Under 2 seconds total.',
                highlight: 'Works everywhere. Every time.'
              },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: i * 0.15 }}
                viewport={{ once: true }}
                whileHover={{ y: -10, scale: 1.02 }}
                className="relative p-8 rounded-3xl bg-gradient-to-br from-gray-50 to-gray-100 hover:shadow-2xl transition-all duration-300 border-2 border-transparent hover:border-accent"
              >
                <div className="absolute -top-6 -left-6 w-14 h-14 rounded-full bg-gradient-to-r from-accent to-neon text-white flex items-center justify-center text-2xl font-black font-accent shadow-lg">
                  {item.step}
                </div>
                <div className="text-7xl mb-6">{item.icon}</div>
                <h3 className="text-2xl font-bold mb-3 text-primary font-heading">{item.title}</h3>
                <p className="text-gray-600 leading-relaxed mb-4">{item.desc}</p>
                <div className="px-4 py-2 rounded-lg bg-gradient-to-r from-accent/10 to-neon/10 border border-accent/20">
                  <p className="text-sm font-semibold text-accent">{item.highlight}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Context-Aware Intelligence */}
      <section className="py-32 gradient-bg-section text-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 font-heading">Context-Aware Intelligence</h2>
            <p className="text-xl opacity-90">AI that understands the app, the vibe, and the situation</p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            {[
              {
                app: 'LinkedIn Message',
                context: '🎯 Professional tone detected',
                example: '"Thank you for the connection! I\'d love to discuss how we can collaborate on this initiative."',
                bg: 'from-blue-500/20 to-blue-700/20'
              },
              {
                app: 'WhatsApp Group',
                context: '😄 Casual & fun detected',
                example: '"Haha that\'s awesome! 😂 Count me in! What time should I be there?"',
                bg: 'from-green-500/20 to-green-700/20'
              },
              {
                app: 'Work Slack',
                context: '💼 Professional but friendly',
                example: '"Thanks for the update! I\'ll have that ready by EOD. Let me know if you need anything else!"',
                bg: 'from-purple-500/20 to-purple-700/20'
              },
              {
                app: 'Dating App',
                context: '💫 Flirty & charming',
                example: '"I was hoping you\'d ask! 😊 Coffee sounds perfect. How about Saturday?"',
                bg: 'from-pink-500/20 to-pink-700/20'
              },
            ].map((scenario, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.9 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
                viewport={{ once: true }}
                whileHover={{ scale: 1.05 }}
                className={`p-8 rounded-3xl bg-gradient-to-br ${scenario.bg} glass-card hover:shadow-2xl transition-all duration-300`}
              >
                <div className="mb-4">
                  <h3 className="text-2xl font-bold mb-2 font-heading">{scenario.app}</h3>
                  <p className="text-sm opacity-75">{scenario.context}</p>
                </div>
                <div className="p-4 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20">
                  <p className="text-white/90 italic">{scenario.example}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Trillion Dollar Industry */}
      <section className="py-32 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-gradient-to-r from-accent/10 to-neon/10 border-2 border-accent/20 mb-8">
              <span className="text-4xl">💎</span>
              <span className="text-2xl font-black text-gradient font-heading">
                Trillion Dollar Industry
              </span>
            </div>
            <h3 className="text-4xl md:text-5xl font-black mb-6 text-primary font-heading">
              The Future of Communication is AI-Powered
            </h3>
            <p className="text-xl text-gray-600 max-w-4xl mx-auto leading-relaxed">
              With <strong>5.3 billion</strong> people using messaging apps daily, the communication industry generates
              <strong className="text-accent"> over $1.2 trillion</strong> in value annually. AgentChains.ai leverages
              enterprise-grade GPT-4o Vision AI to revolutionize how billions communicate across all platforms.
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-16 max-w-5xl mx-auto">
              {[
                { number: '$1.2T', label: 'Industry Value' },
                { number: '5.3B', label: 'Daily Users' },
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
                  <div className="text-5xl font-black text-gradient mb-2 font-accent">
                    {stat.number}
                  </div>
                  <div className="text-sm font-semibold text-gray-600">{stat.label}</div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Works Everywhere */}
      <section className="py-32 gradient-bg-section text-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 font-heading">Works Everywhere</h2>
            <p className="text-xl opacity-90 font-accent">Don't even think about what app it is</p>
          </div>

          <div className="grid grid-cols-3 md:grid-cols-6 gap-6">
            {[
              { name: 'WhatsApp', emoji: '💬' },
              { name: 'iMessage', emoji: '💬' },
              { name: 'Instagram', emoji: '📸' },
              { name: 'LinkedIn', emoji: '💼' },
              { name: 'Email', emoji: '📧' },
              { name: 'Slack', emoji: '💬' },
              { name: 'Discord', emoji: '🎮' },
              { name: 'Telegram', emoji: '✈️' },
              { name: 'Tinder', emoji: '❤️' },
              { name: 'X (Twitter)', emoji: '🐦' },
              { name: 'Teams', emoji: '👥' },
              { name: 'Any App', emoji: '✨' },
            ].map((app, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
                whileHover={{ scale: 1.1, y: -5 }}
                className="p-6 rounded-2xl glass-card hover:bg-white/10 transition-all duration-300 text-center"
              >
                <div className="text-4xl mb-2">{app.emoji}</div>
                <p className="text-sm font-semibold">{app.name}</p>
              </motion.div>
            ))}
          </div>

          <div className="mt-16 text-center max-w-3xl mx-auto">
            <p className="text-xl opacity-90 leading-relaxed">
              AgentChains.ai automatically detects the app, analyzes the conversation context, and adapts the tone.
              <strong className="text-neon"> Professional for LinkedIn. Casual for WhatsApp. Charming for dating apps.</strong>
            </p>
          </div>
        </div>
      </section>

      {/* Interactive Demo */}
      <section id="demo" className="py-32 bg-white">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-5xl md:text-6xl font-black mb-4 text-primary font-heading">Try It Yourself</h2>
            <p className="text-xl text-gray-600">Interactive demo with mock data - No sign-up required</p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            {/* Demo Controls */}
            <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-3xl p-8 shadow-xl">
              <h3 className="text-3xl font-bold mb-6 text-primary font-heading">Choose Your Tone</h3>

              <div className="mb-8">
                <label className="block text-sm font-bold mb-3 text-gray-700">🎭 Reply Tone</label>
                <div className="grid grid-cols-2 gap-3">
                  {['professional', 'friendly', 'funny', 'flirty'].map((tone) => (
                    <button
                      key={tone}
                      onClick={() => setSelectedTone(tone)}
                      className={`px-6 py-4 rounded-xl font-bold transition-all duration-300 ${
                        selectedTone === tone
                          ? 'bg-gradient-to-r from-accent to-neon text-white shadow-lg scale-105'
                          : 'bg-white text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      {tone.charAt(0).toUpperCase() + tone.slice(1)}
                    </button>
                  ))}
                </div>
              </div>

              <button
                onClick={generateReplies}
                disabled={loading}
                className="w-full px-8 py-5 rounded-2xl font-bold text-lg text-white bg-gradient-to-r from-accent to-neon hover:shadow-2xl hover:-translate-y-1 transition-all duration-300 disabled:opacity-50"
              >
                {loading ? '✨ Generating...' : '✨ Generate Smart Replies'}
              </button>
            </div>

            {/* Results */}
            <div className="bg-gradient-to-br from-primary to-gray-900 rounded-3xl p-8 shadow-xl">
              <h3 className="text-3xl font-bold mb-6 text-white font-heading">Your Smart Replies</h3>

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
                      className="p-5 rounded-2xl glass-card hover:bg-white/10 cursor-pointer hover:scale-105 transition-all duration-300 group"
                    >
                      <p className="text-white leading-relaxed">{reply}</p>
                      <span className="float-right text-2xl opacity-50 group-hover:opacity-100 transition">📋</span>
                    </motion.div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Privacy & Security */}
      <section className="py-32 gradient-bg-section text-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 font-heading">Privacy-First Design</h2>
            <p className="text-xl opacity-90">Your conversations are yours. Period.</p>
          </div>

          <div className="grid md:grid-cols-4 gap-8">
            {[
              { icon: '🔒', title: 'Zero Data Retention', desc: 'Screenshots processed in-memory, never stored' },
              { icon: '🛡️', title: 'End-to-End Encrypted', desc: 'Your conversations stay 100% private' },
              { icon: '🚫', title: 'No Tracking', desc: 'We don\'t log, analyze, or sell your data' },
              { icon: '✅', title: 'SOC 2 Compliant', desc: 'Enterprise-grade security standards' },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                viewport={{ once: true }}
                className="text-center p-8 rounded-3xl glass-card hover:bg-white/10 transition-all duration-300"
              >
                <div className="text-6xl mb-4">{item.icon}</div>
                <h3 className="text-xl font-bold mb-3 font-heading">{item.title}</h3>
                <p className="text-sm opacity-75 leading-relaxed">{item.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Enterprise Infrastructure - Temporal.io */}
      <section className="py-32 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <div className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-gradient-to-r from-blue-500/10 to-purple-500/10 border-2 border-blue-500/20 mb-8">
              <span className="text-4xl">⚡</span>
              <span className="text-2xl font-black text-gradient font-heading">Powered by Temporal.io</span>
            </div>
            <h2 className="text-5xl md:text-6xl font-black mb-4 text-primary font-heading">Enterprise-Grade Infrastructure</h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Built on the same workflow orchestration platform trusted by <strong className="text-accent">NVIDIA, Salesforce, and Twilio</strong>
            </p>
          </div>

          <div className="grid md:grid-cols-4 gap-8 mb-16">
            {[
              { icon: '🚀', title: '99.99% Uptime', desc: 'Enterprise SLA with automatic failover' },
              { icon: '⚡', title: 'Zero Lost Requests', desc: 'Durable execution guarantees every request completes' },
              { icon: '🔄', title: 'Auto-Recovery <1s', desc: 'Instant retry and recovery on any failure' },
              { icon: '📊', title: 'Full Visibility', desc: 'Track every workflow execution in real-time' },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
                viewport={{ once: true }}
                className="text-center p-8 rounded-3xl bg-gradient-to-br from-gray-50 to-gray-100 hover:shadow-xl transition-all duration-300"
              >
                <div className="text-6xl mb-4">{item.icon}</div>
                <h3 className="text-2xl font-bold mb-2 text-primary font-heading">{item.title}</h3>
                <p className="text-sm text-gray-600 leading-relaxed">{item.desc}</p>
              </motion.div>
            ))}
          </div>

          <div className="max-w-4xl mx-auto bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 p-1 rounded-3xl">
            <div className="bg-white rounded-3xl p-12">
              <div className="text-center mb-8">
                <h3 className="text-3xl font-black mb-4 text-primary font-heading">Why Temporal.io?</h3>
                <p className="text-lg text-gray-600">The world's most reliable workflow orchestration platform</p>
              </div>
              <div className="grid md:grid-cols-2 gap-6">
                <div className="flex items-start gap-4">
                  <span className="text-2xl">✓</span>
                  <div>
                    <h4 className="font-bold text-primary mb-1">Automatic State Preservation</h4>
                    <p className="text-sm text-gray-600">Workflows capture state at every step and can recover from any failure</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <span className="text-2xl">✓</span>
                  <div>
                    <h4 className="font-bold text-primary mb-1">Battle-Tested at Scale</h4>
                    <p className="text-sm text-gray-600">20+ years of development experience from AWS & Azure engineers</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <span className="text-2xl">✓</span>
                  <div>
                    <h4 className="font-bold text-primary mb-1">Zero-Downtime Deployments</h4>
                    <p className="text-sm text-gray-600">Update code without interrupting running workflows</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <span className="text-2xl">✓</span>
                  <div>
                    <h4 className="font-bold text-primary mb-1">Guaranteed Execution</h4>
                    <p className="text-sm text-gray-600">Every screenshot-to-reply workflow completes, no matter what</p>
                  </div>
                </div>
              </div>
              <div className="mt-8 pt-8 border-t border-gray-200 text-center">
                <p className="text-sm text-gray-500 italic">
                  "Temporal does to backend and infra, what React did to frontend" - <strong>Guillermo Rauch, CEO of Vercel</strong>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-32 bg-gradient-to-br from-gray-50 to-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 text-primary font-heading">Simple Pricing</h2>
            <p className="text-xl text-gray-600">Start free, upgrade when you need more</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                name: 'Free',
                price: '$0',
                period: 'forever',
                features: ['20 replies/day', '4 tone modes', 'All platforms', 'Privacy-first'],
                cta: 'Get Started Free',
                popular: false
              },
              {
                name: 'Pro',
                price: '$9.99',
                period: '/month',
                features: ['Unlimited replies', '4 tone modes + custom', 'Priority AI processing', 'Email support'],
                cta: 'Start 7-Day Trial',
                popular: true
              },
              {
                name: 'Enterprise',
                price: 'Custom',
                period: '',
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
                    ? 'bg-gradient-to-br from-accent to-neon text-white scale-105 shadow-2xl'
                    : 'bg-gradient-to-br from-gray-50 to-gray-100 hover:shadow-xl'
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-6 py-2 rounded-full bg-primary text-white font-bold text-sm">
                    ⭐ MOST POPULAR
                  </div>
                )}
                <h3 className="text-2xl font-bold mb-4 font-heading">{plan.name}</h3>
                <div className="mb-6">
                  <span className="text-6xl font-black font-accent">{plan.price}</span>
                  <span className="text-lg opacity-75">{plan.period}</span>
                </div>
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
                    : 'bg-gradient-to-r from-accent to-neon text-white hover:shadow-xl hover:-translate-y-1'
                }`}>
                  {plan.cta}
                </button>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Waitlist Form */}
      <section id="waitlist" className="py-32 bg-gradient-to-br from-primary via-gray-900 to-accent text-white relative overflow-hidden">
        {/* Animated Background */}
        <div className="absolute inset-0">
          <motion.div
            className="absolute w-96 h-96 bg-neon/10 rounded-full blur-3xl"
            animate={{
              x: [0, 100, 0],
              y: [0, -100, 0],
            }}
            transition={{ duration: 25, repeat: Infinity }}
            style={{ top: '10%', left: '5%' }}
          />
          <motion.div
            className="absolute w-80 h-80 bg-accent/10 rounded-full blur-3xl"
            animate={{
              x: [0, -80, 0],
              y: [0, 80, 0],
            }}
            transition={{ duration: 20, repeat: Infinity }}
            style={{ bottom: '10%', right: '5%' }}
          />
        </div>

        <div className="max-w-4xl mx-auto px-6 relative z-10">
          <div className="text-center mb-16">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
            >
              <h2 className="text-5xl md:text-6xl font-black mb-4 font-heading">Join the Waitlist</h2>
              <p className="text-xl opacity-90">Help us build the perfect AI reply assistant. Share your thoughts!</p>
            </motion.div>
          </div>

          {!formSubmitted ? (
            <motion.form
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              onSubmit={handleFormSubmit}
              className="glass-card p-8 md:p-12"
            >
              {/* Name & Email */}
              <div className="grid md:grid-cols-2 gap-6 mb-6">
                <div>
                  <label className="block text-sm font-bold mb-2">Name *</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition"
                    placeholder="Your name"
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-2">Email *</label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition"
                    placeholder="your@email.com"
                  />
                </div>
              </div>

              {/* Phone (optional) */}
              <div className="mb-6">
                <label className="block text-sm font-bold mb-2">Phone (Optional)</label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition"
                  placeholder="+1 (555) 123-4567"
                />
              </div>

              {/* Company & Role */}
              <div className="grid md:grid-cols-2 gap-6 mb-8">
                <div>
                  <label className="block text-sm font-bold mb-2">Company (Optional)</label>
                  <input
                    type="text"
                    value={formData.company}
                    onChange={(e) => setFormData({...formData, company: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition"
                    placeholder="Your company"
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-2">Role (Optional)</label>
                  <input
                    type="text"
                    value={formData.role}
                    onChange={(e) => setFormData({...formData, role: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition"
                    placeholder="Job title or role"
                  />
                </div>
              </div>

              {/* ChatGPT Screenshot Usage */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  Are you currently using ChatGPT screenshot-and-paste for messaging replies? *
                </label>
                <div className="space-y-3">
                  {[
                    { value: 'yes-all-the-time', label: 'Yes, all the time' },
                    { value: 'sometimes', label: 'Sometimes' },
                    { value: 'tried-too-slow', label: 'Tried it, but it\'s too slow' },
                    { value: 'never', label: 'No, never tried it' },
                  ].map((option) => (
                    <label key={option.value} className="flex items-center gap-3 cursor-pointer group">
                      <input
                        type="radio"
                        name="usingChatGPT"
                        value={option.value}
                        checked={formData.usingChatGPT === option.value}
                        onChange={(e) => setFormData({...formData, usingChatGPT: e.target.value})}
                        className="w-5 h-5 text-neon focus:ring-neon"
                        required
                      />
                      <span className="group-hover:text-neon transition">{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Messaging Struggles */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  What's your biggest struggle with messaging? (Check all that apply)
                </label>
                <div className="space-y-3">
                  {[
                    'Taking too long to reply',
                    'Don\'t know what to say',
                    'Want to sound more professional',
                    'Struggle with tone (too formal/casual)',
                    'Language barriers',
                    'Keeping up with multiple conversations',
                  ].map((struggle) => (
                    <label key={struggle} className="flex items-center gap-3 cursor-pointer group">
                      <input
                        type="checkbox"
                        checked={formData.struggles.includes(struggle)}
                        onChange={() => handleCheckboxChange('struggles', struggle)}
                        className="w-5 h-5 rounded text-neon focus:ring-neon"
                      />
                      <span className="group-hover:text-neon transition">{struggle}</span>
                    </label>
                  ))}
                  <input
                    type="text"
                    value={formData.strugglesOther}
                    onChange={(e) => setFormData({...formData, strugglesOther: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition mt-2"
                    placeholder="Other (please specify)"
                  />
                </div>
              </div>

              {/* Biggest Pain Point */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  What's your #1 messaging frustration right now? *
                </label>
                <textarea
                  required
                  value={formData.biggestPainPoint}
                  onChange={(e) => setFormData({...formData, biggestPainPoint: e.target.value})}
                  rows={4}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition resize-none"
                  placeholder="Tell us the one thing that frustrates you most about messaging (e.g., 'Spending 2 hours daily crafting LinkedIn responses')"
                />
              </div>

              {/* Apps Used */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  Which apps do you use most for messaging? (Check all that apply)
                </label>
                <div className="grid md:grid-cols-2 gap-3">
                  {[
                    'WhatsApp',
                    'iMessage',
                    'Instagram',
                    'LinkedIn',
                    'Email',
                    'Slack',
                    'Dating apps (Tinder, Bumble, etc.)',
                    'Discord',
                  ].map((app) => (
                    <label key={app} className="flex items-center gap-3 cursor-pointer group">
                      <input
                        type="checkbox"
                        checked={formData.apps.includes(app)}
                        onChange={() => handleCheckboxChange('apps', app)}
                        className="w-5 h-5 rounded text-neon focus:ring-neon"
                      />
                      <span className="group-hover:text-neon transition">{app}</span>
                    </label>
                  ))}
                </div>
                <input
                  type="text"
                  value={formData.appsOther}
                  onChange={(e) => setFormData({...formData, appsOther: e.target.value})}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition mt-3"
                  placeholder="Other apps (please specify)"
                />
              </div>

              {/* Time Spent */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  How much time do you spend replying to messages daily? *
                </label>
                <select
                  required
                  value={formData.timeSpent}
                  onChange={(e) => setFormData({...formData, timeSpent: e.target.value})}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white focus:border-neon focus:outline-none transition"
                >
                  <option value="" className="bg-primary">Select...</option>
                  <option value="less-than-30min" className="bg-primary">Less than 30 minutes</option>
                  <option value="30min-1hour" className="bg-primary">30 min - 1 hour</option>
                  <option value="1-2hours" className="bg-primary">1-2 hours</option>
                  <option value="2plus-hours" className="bg-primary">2+ hours</option>
                </select>
              </div>

              {/* Willing to Pay */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  Would you pay $9.99/month for AgentChains.ai? *
                </label>
                <div className="space-y-3">
                  {[
                    { value: 'yes', label: 'Yes, absolutely!' },
                    { value: 'maybe', label: 'Maybe, need to see it first' },
                    { value: 'no', label: 'No, prefer free version' },
                  ].map((option) => (
                    <label key={option.value} className="flex items-center gap-3 cursor-pointer group">
                      <input
                        type="radio"
                        name="willingToPay"
                        value={option.value}
                        checked={formData.willingToPay === option.value}
                        onChange={(e) => setFormData({...formData, willingToPay: e.target.value})}
                        className="w-5 h-5 text-neon focus:ring-neon"
                        required
                      />
                      <span className="group-hover:text-neon transition">{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Referral Source */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  How did you hear about AgentChains.ai? *
                </label>
                <select
                  required
                  value={formData.referralSource}
                  onChange={(e) => setFormData({...formData, referralSource: e.target.value})}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white focus:border-neon focus:outline-none transition"
                >
                  <option value="" className="bg-primary">Select...</option>
                  <option value="twitter" className="bg-primary">Twitter/X</option>
                  <option value="linkedin" className="bg-primary">LinkedIn</option>
                  <option value="friend" className="bg-primary">Friend or colleague</option>
                  <option value="google" className="bg-primary">Google search</option>
                  <option value="reddit" className="bg-primary">Reddit</option>
                  <option value="youtube" className="bg-primary">YouTube</option>
                  <option value="other" className="bg-primary">Other</option>
                </select>
              </div>

              {/* Ideas */}
              <div className="mb-8">
                <label className="block text-sm font-bold mb-3">
                  What ideas do you have for AgentChains.ai? What features would you love to see?
                </label>
                <textarea
                  value={formData.ideas}
                  onChange={(e) => setFormData({...formData, ideas: e.target.value})}
                  rows={6}
                  className="w-full px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/50 focus:border-neon focus:outline-none transition resize-none"
                  placeholder="Share your thoughts, feature requests, or any ideas you have to make AgentChains.ai better..."
                />
              </div>

              {/* Beta Tester */}
              <div className="mb-8">
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={formData.betaTester}
                    onChange={(e) => setFormData({...formData, betaTester: e.target.checked})}
                    className="w-5 h-5 rounded text-neon focus:ring-neon"
                  />
                  <span className="font-bold group-hover:text-neon transition">
                    🚀 I want early beta access and am willing to provide feedback!
                  </span>
                </label>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={formSubmitting}
                className="w-full px-8 py-5 rounded-2xl font-bold text-lg bg-gradient-to-r from-accent to-neon text-white hover:shadow-2xl hover:-translate-y-1 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed glow-neon"
              >
                {formSubmitting ? (
                  <span className="flex items-center justify-center gap-3">
                    <div className="w-6 h-6 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                    Submitting...
                  </span>
                ) : (
                  'Join the Waitlist 🚀'
                )}
              </button>

              <p className="text-sm opacity-75 text-center mt-4">
                🔒 Your data is 100% secure and will never be shared
              </p>
            </motion.form>
          ) : (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="glass-card p-12 text-center"
            >
              <div className="text-8xl mb-6">🎉</div>
              <h3 className="text-4xl font-black mb-4 font-heading">You're on the List!</h3>
              <p className="text-xl opacity-90 mb-6">
                Thank you for joining! We'll keep you updated on our progress and let you know when we launch.
              </p>
              <p className="text-lg opacity-75">
                Check your email for confirmation and exclusive early access details.
              </p>
            </motion.div>
          )}
        </div>
      </section>

      {/* Roadmap */}
      <section className="py-32 gradient-bg-section text-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-20">
            <h2 className="text-5xl md:text-6xl font-black mb-4 font-heading">Coming Soon</h2>
            <p className="text-xl opacity-90">Exciting features on the horizon</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              { icon: '📱', title: 'iOS App', status: 'In Development', date: 'Coming Soon', highlight: true },
              { icon: '🤖', title: 'Android App', status: 'Coming Soon', date: 'Coming Soon', highlight: false },
              { icon: '🌐', title: 'Browser Extension', status: 'Planned', date: 'Coming Soon', highlight: false },
              { icon: '🔌', title: 'Developer API', status: 'Planned', date: '2025', highlight: false },
              { icon: '🌍', title: 'Multi-Language', status: 'Planned', date: '2025', highlight: false },
              { icon: '🎨', title: 'Custom AI Training', status: 'Research', date: '2026', highlight: false },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.9 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
                viewport={{ once: true }}
                className={`p-8 rounded-3xl glass-card hover:bg-white/10 transition-all duration-300 ${
                  item.highlight ? 'border-2 border-neon glow-neon' : ''
                }`}
              >
                <div className="text-6xl mb-4">{item.icon}</div>
                <h3 className="text-2xl font-bold mb-2 font-heading">{item.title}</h3>
                <p className="text-sm opacity-75 mb-2">{item.status}</p>
                <p className="text-xs opacity-50">{item.date}</p>
                {item.highlight && (
                  <div className="mt-4 px-4 py-2 rounded-lg bg-neon/20 border border-neon">
                    <p className="text-sm font-bold text-neon">🚀 Active Development</p>
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-32 bg-gradient-to-r from-accent via-primary to-neon text-white text-center">
        <div className="max-w-4xl mx-auto px-6">
          <h2 className="text-5xl md:text-6xl font-black mb-6 font-heading">Ready to Transform Your Messaging?</h2>
          <p className="text-2xl mb-12 opacity-95">Join 10,000+ people on the waitlist. Coming Soon!</p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
            <button className="px-12 py-6 rounded-2xl font-bold text-lg bg-white text-primary hover:shadow-2xl hover:-translate-y-2 transition-all duration-300">
              Join Waitlist Now
            </button>
            <button className="px-12 py-6 rounded-2xl font-bold text-lg glass hover:bg-white/30 hover:-translate-y-2 transition-all duration-300">
              Watch Full Demo
            </button>
          </div>
          <p className="mt-8 text-lg opacity-90">🎉 No credit card required • Privacy-first guarantee • Coming Soon</p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-primary text-white py-16">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid md:grid-cols-4 gap-12 mb-12">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <img
                  src="/assets/logos/logo-light.svg"
                  alt="AgentChains.ai"
                  className="h-8"
                />
              </div>
              <p className="text-sm opacity-75">Screenshot → AI analyzes → clipboard → paste</p>
              <p className="text-xs opacity-60 mt-2">Private by design • Encrypted • No storage</p>
            </div>

            <div>
              <h4 className="font-bold mb-4 font-heading">Product</h4>
              <ul className="space-y-2 text-sm opacity-75">
                <li><a href="#how-it-works" className="hover:text-neon transition">How It Works</a></li>
                <li><a href="#features" className="hover:text-neon transition">Features</a></li>
                <li><a href="#pricing" className="hover:text-neon transition">Pricing</a></li>
                <li><a href="#demo" className="hover:text-neon transition">Try Demo</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-bold mb-4 font-heading">Company</h4>
              <ul className="space-y-2 text-sm opacity-75">
                <li><a href="#" className="hover:text-neon transition">About Us</a></li>
                <li><a href="#" className="hover:text-neon transition">Blog</a></li>
                <li><a href="#" className="hover:text-neon transition">Careers</a></li>
                <li><a href="#" className="hover:text-neon transition">Contact</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-bold mb-4 font-heading">Legal</h4>
              <ul className="space-y-2 text-sm opacity-75">
                <li><a href="#" className="hover:text-neon transition">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-neon transition">Terms of Service</a></li>
                <li><a href="#" className="hover:text-neon transition">Security</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-white/10 pt-8">
            <div className="flex flex-col items-center gap-4">
              {/* Copyright & LinkedIn */}
              <div className="flex items-center gap-3">
                <p className="text-sm opacity-75">
                  © 2025 AgentChains.ai. Built with ❤️ and GPT-4o Vision.
                </p>
                <a
                  href="https://www.linkedin.com/in/akhil-reddy-danda-1a74b214b/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:opacity-80 transition-opacity"
                  aria-label="Connect on LinkedIn"
                >
                  <svg className="w-5 h-5 text-[#0A66C2]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                  </svg>
                </a>
              </div>

              {/* Built by Attribution */}
              <div className="text-center">
                <p className="text-sm opacity-75">
                  Built by{' '}
                  <a
                    href="https://www.linkedin.com/in/akhil-reddy-danda-1a74b214b/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-neon hover:text-white font-semibold transition-colors underline"
                  >
                    Akhil Reddy Danda
                  </a>
                </p>
                <p className="text-xs opacity-60 mt-1">
                  Want to reach out to the developer?{' '}
                  <a
                    href="https://www.linkedin.com/in/akhil-reddy-danda-1a74b214b/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-neon hover:text-white transition-colors underline"
                  >
                    Connect on LinkedIn
                  </a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
