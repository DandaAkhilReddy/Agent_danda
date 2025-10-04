'use client'

import { useState, useEffect } from 'react'
import { collection, query, orderBy, getDocs } from 'firebase/firestore'
import { db } from '../../lib/firebase'
import * as XLSX from 'xlsx'

interface WaitlistSubmission {
  id: string
  name: string
  email: string
  phone: string
  usingChatGPT: string
  struggles: string[]
  strugglesOther: string
  apps: string[]
  appsOther: string
  ideas: string
  timeSpent: string
  submittedAt: string
}

export default function AdminDashboard() {
  const [password, setPassword] = useState('')
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [submissions, setSubmissions] = useState<WaitlistSubmission[]>([])
  const [loading, setLoading] = useState(false)
  const [stats, setStats] = useState({
    total: 0,
    usingChatGPT: 0,
    avgTimeSpent: ''
  })

  const ADMIN_PASSWORD = 'AgentChains2025' // Change this to a secure password

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault()
    if (password === ADMIN_PASSWORD) {
      setIsAuthenticated(true)
      fetchSubmissions()
    } else {
      alert('Incorrect password')
    }
  }

  const fetchSubmissions = async () => {
    setLoading(true)
    try {
      const q = query(collection(db, 'waitlist-submissions'), orderBy('submittedAt', 'desc'))
      const querySnapshot = await getDocs(q)

      const data: WaitlistSubmission[] = []
      querySnapshot.forEach((doc) => {
        data.push({
          id: doc.id,
          ...doc.data()
        } as WaitlistSubmission)
      })

      setSubmissions(data)

      // Calculate stats
      const usingChatGPT = data.filter(s => s.usingChatGPT === 'yes-all-the-time' || s.usingChatGPT === 'sometimes').length

      setStats({
        total: data.length,
        usingChatGPT,
        avgTimeSpent: calculateAvgTime(data)
      })
    } catch (error) {
      console.error('Error fetching submissions:', error)
      alert('Error loading data. Check Firebase configuration.')
    } finally {
      setLoading(false)
    }
  }

  const calculateAvgTime = (data: WaitlistSubmission[]) => {
    const timeMap: { [key: string]: number } = {
      'less-than-30min': 15,
      '30min-1hour': 45,
      '1-2hours': 90,
      '2plus-hours': 150
    }

    const total = data.reduce((sum, s) => sum + (timeMap[s.timeSpent] || 0), 0)
    const avg = total / (data.length || 1)

    if (avg < 30) return '< 30 min'
    if (avg < 60) return '30-60 min'
    if (avg < 120) return '1-2 hours'
    return '2+ hours'
  }

  const exportToExcel = () => {
    const exportData = submissions.map(s => ({
      'Name': s.name,
      'Email': s.email,
      'Phone': s.phone || 'N/A',
      'Using ChatGPT?': s.usingChatGPT.replace(/-/g, ' '),
      'Struggles': s.struggles.join(', ') + (s.strugglesOther ? `, ${s.strugglesOther}` : ''),
      'Apps': s.apps.join(', ') + (s.appsOther ? `, ${s.appsOther}` : ''),
      'Time Spent Daily': s.timeSpent.replace(/-/g, ' '),
      'Ideas': s.ideas || 'None provided',
      'Submitted': new Date(s.submittedAt).toLocaleString()
    }))

    const worksheet = XLSX.utils.json_to_sheet(exportData)
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Waitlist')

    // Auto-size columns
    const maxWidth = 50
    const colWidths = Object.keys(exportData[0] || {}).map(key => ({
      wch: Math.min(
        Math.max(
          key.length,
          ...exportData.map(row => String(row[key as keyof typeof row] || '').length)
        ),
        maxWidth
      )
    }))
    worksheet['!cols'] = colWidths

    const date = new Date().toISOString().split('T')[0]
    XLSX.writeFile(workbook, `AgentChains_Waitlist_${date}.xlsx`)
  }

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary via-gray-900 to-accent">
        <div className="bg-white rounded-3xl p-12 shadow-2xl max-w-md w-full">
          <div className="text-center mb-8">
            <span className="text-6xl mb-4 block">🔒</span>
            <h1 className="text-4xl font-black text-primary mb-2">Admin Login</h1>
            <p className="text-gray-600">Enter password to access dashboard</p>
          </div>

          <form onSubmit={handleLogin}>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Admin Password"
              className="w-full px-6 py-4 rounded-xl border-2 border-gray-200 focus:border-accent focus:outline-none mb-6 text-lg"
              autoFocus
            />
            <button
              type="submit"
              className="w-full px-8 py-4 rounded-xl font-bold text-lg bg-gradient-to-r from-accent to-neon text-white hover:shadow-2xl transition-all duration-300"
            >
              Login
            </button>
          </form>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-3xl p-8 shadow-lg mb-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-4xl font-black text-primary mb-2">Waitlist Dashboard</h1>
              <p className="text-gray-600">Manage and export waitlist submissions</p>
            </div>
            <button
              onClick={exportToExcel}
              disabled={submissions.length === 0}
              className="px-8 py-4 rounded-xl font-bold bg-gradient-to-r from-accent to-neon text-white hover:shadow-xl transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-3"
            >
              <span>📊</span>
              <span>Export to Excel</span>
            </button>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-6">
            <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-6 rounded-2xl">
              <div className="text-4xl font-black text-blue-600 mb-2">{stats.total}</div>
              <div className="text-sm font-semibold text-gray-600">Total Submissions</div>
            </div>
            <div className="bg-gradient-to-br from-green-50 to-green-100 p-6 rounded-2xl">
              <div className="text-4xl font-black text-green-600 mb-2">{stats.usingChatGPT}</div>
              <div className="text-sm font-semibold text-gray-600">Using ChatGPT</div>
            </div>
            <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-6 rounded-2xl">
              <div className="text-2xl font-black text-purple-600 mb-2">{stats.avgTimeSpent}</div>
              <div className="text-sm font-semibold text-gray-600">Avg Time Spent</div>
            </div>
          </div>

          <button
            onClick={fetchSubmissions}
            disabled={loading}
            className="mt-6 px-6 py-3 rounded-xl font-semibold text-primary border-2 border-primary hover:bg-primary hover:text-white transition-all duration-300"
          >
            {loading ? 'Refreshing...' : '🔄 Refresh Data'}
          </button>
        </div>

        {/* Submissions Table */}
        <div className="bg-white rounded-3xl shadow-lg overflow-hidden">
          <div className="p-6 bg-gradient-to-r from-primary to-accent text-white">
            <h2 className="text-2xl font-bold">Submissions ({submissions.length})</h2>
          </div>

          {loading ? (
            <div className="p-12 text-center">
              <div className="inline-block w-12 h-12 border-4 border-primary/30 border-t-primary rounded-full animate-spin mb-4"></div>
              <p className="text-gray-600">Loading submissions...</p>
            </div>
          ) : submissions.length === 0 ? (
            <div className="p-12 text-center">
              <div className="text-6xl mb-4">📝</div>
              <p className="text-xl text-gray-600">No submissions yet</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Name</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Email</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Phone</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Using ChatGPT?</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Top Struggles</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Time/Day</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Ideas</th>
                    <th className="px-6 py-4 text-left text-sm font-bold text-gray-700">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {submissions.map((submission, index) => (
                    <tr key={submission.id} className={`${index % 2 === 0 ? 'bg-white' : 'bg-gray-50'} hover:bg-blue-50 transition-colors`}>
                      <td className="px-6 py-4 text-sm font-semibold text-gray-900">{submission.name}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{submission.email}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{submission.phone || '-'}</td>
                      <td className="px-6 py-4 text-sm">
                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          submission.usingChatGPT.includes('yes') || submission.usingChatGPT.includes('sometimes')
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-100 text-gray-700'
                        }`}>
                          {submission.usingChatGPT.replace(/-/g, ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">
                        {submission.struggles.slice(0, 2).join(', ')}
                        {submission.struggles.length > 2 && '...'}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{submission.timeSpent.replace(/-/g, ' ')}</td>
                      <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">
                        {submission.ideas || '-'}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        {new Date(submission.submittedAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
