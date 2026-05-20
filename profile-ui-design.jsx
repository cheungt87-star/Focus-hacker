import React, { useState } from 'react';
import { TrendingUp, Zap, Target, Calendar, BarChart3 } from 'lucide-react';

export default function ProfilePage() {
  const [timePeriod, setTimePeriod] = useState('week'); // week, month, year, day
  const [targetType, setTargetType] = useState('default'); // default, personal

  // Level color configuration
  const levelColors = {
    'Rookie': {
      bg: 'from-cyan-400 to-blue-500',
      glow: 'cyan-500',
      border: 'cyan-300',
      text: 'from-cyan-50 to-blue-100',
      shadow: 'shadow-lg shadow-cyan-500/50'
    },
    'Amateur': {
      bg: 'from-emerald-400 to-teal-500',
      glow: 'emerald-500',
      border: 'emerald-300',
      text: 'from-emerald-50 to-teal-100',
      shadow: 'shadow-lg shadow-emerald-500/50'
    },
    'Semi-Pro': {
      bg: 'from-teal-400 to-cyan-600',
      glow: 'teal-500',
      border: 'teal-300',
      text: 'from-teal-50 to-cyan-100',
      shadow: 'shadow-lg shadow-teal-500/50'
    },
    'Professional': {
      bg: 'from-blue-500 to-indigo-600',
      glow: 'blue-600',
      border: 'blue-400',
      text: 'from-blue-50 to-indigo-100',
      shadow: 'shadow-lg shadow-blue-600/50'
    },
    'All-Star': {
      bg: 'from-yellow-400 to-amber-500',
      glow: 'yellow-500',
      border: 'yellow-300',
      text: 'from-yellow-50 to-amber-100',
      shadow: 'shadow-lg shadow-yellow-500/50'
    },
    'Champion': {
      bg: 'from-amber-400 to-orange-500',
      glow: 'orange-500',
      border: 'amber-300',
      text: 'from-amber-50 to-orange-100',
      shadow: 'shadow-lg shadow-orange-500/50'
    },
    'Elite': {
      bg: 'from-red-500 to-rose-600',
      glow: 'red-600',
      border: 'red-400',
      text: 'from-red-50 to-rose-100',
      shadow: 'shadow-lg shadow-red-600/50'
    },
    'Hall of Famer': {
      bg: 'from-purple-600 to-indigo-700',
      glow: 'purple-700',
      border: 'purple-500',
      text: 'from-purple-50 to-indigo-100',
      shadow: 'shadow-lg shadow-purple-700/50'
    },
    'Legend': {
      bg: 'from-violet-600 to-purple-700',
      glow: 'violet-700',
      border: 'violet-500',
      text: 'from-violet-50 to-purple-100',
      shadow: 'shadow-lg shadow-violet-700/50'
    },
    'GOAT': {
      bg: 'from-yellow-500 via-amber-500 to-yellow-600',
      glow: 'yellow-600',
      border: 'yellow-400',
      text: 'from-yellow-50 to-amber-100',
      shadow: 'shadow-2xl shadow-yellow-600/60'
    }
  };

  // Mock data
  const userData = {
    name: 'Alex Chen',
    currentLevel: 'Champion',
    currentXP: 36000,
    nextLevelXP: 56000,
    xpProgress: (36000 / 56000) * 100,
    defaultStreak: 12,
    personalStreak: 7,
    defaultTarget: 800,
    personalTarget: 600,
    currentWeekMinutes: 450,
  };

  const currentLevelColors = levelColors[userData.currentLevel] || levelColors['Rookie'];

  // Mock weekly data
  const weeklyData = [
    { week: 'Week 1', minutes: 820, target: 800, hit: true },
    { week: 'Week 2', minutes: 950, target: 800, hit: true },
    { week: 'Week 3', minutes: 750, target: 800, hit: false },
    { week: 'Week 4', minutes: 890, target: 800, hit: true },
    { week: 'Week 5', minutes: 810, target: 800, hit: true },
    { week: 'Week 6', minutes: 600, target: 600, hit: true }, // personal target
    { week: 'Week 7', minutes: 580, target: 600, hit: false },
    { week: 'Week 8', minutes: 640, target: 600, hit: true },
  ];

  // Mock daily data
  const dailyData = [
    { day: 'Mon', minutes: 120 },
    { day: 'Tue', minutes: 95 },
    { day: 'Wed', minutes: 0 },
    { day: 'Thu', minutes: 110 },
    { day: 'Fri', minutes: 95 },
    { day: 'Sat', minutes: 30 },
    { day: 'Sun', minutes: 0 },
  ];

  const currentTarget = targetType === 'default' ? userData.defaultTarget : userData.personalTarget;
  const currentStreak = targetType === 'default' ? userData.defaultStreak : userData.personalStreak;

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-slate-100 p-6">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900">My Profile</h1>
          <p className="text-slate-600 mt-1">{userData.name}</p>
        </div>

        {/* PROFILE CARD - Hero Section */}
        <div className={`bg-gradient-to-br ${currentLevelColors.bg} rounded-xl border-2 ${currentLevelColors.border} p-8 mb-8 ${currentLevelColors.shadow} backdrop-blur-sm`}>
          <div className="flex items-stretch justify-between gap-8">
            {/* Left: User Info & Stats */}
            <div className="flex-1 flex flex-col justify-between">
              {/* User Info & Greeting */}
              <div>
                <p className="text-white text-opacity-70 text-sm mb-1 drop-shadow">Welcome back</p>
                <h1 className="text-4xl font-bold text-white drop-shadow-lg mb-1">{userData.name}</h1>
                <p className="text-white text-opacity-80 text-base mb-6 drop-shadow">@{userData.name.toLowerCase().replace(' ', '')}</p>

                {/* Stats Display - Three columns */}
                <div className="grid grid-cols-3 gap-6 mb-8">
                  {/* Lifetime XP */}
                  <div>
                    <p className="text-xs text-white text-opacity-80 font-medium mb-2 flex items-center gap-2 drop-shadow">
                      <TrendingUp className="w-4 h-4" />
                      LIFETIME XP
                    </p>
                    <p className="text-5xl font-bold text-white drop-shadow-lg">{(userData.currentXP / 1000).toFixed(1)}k</p>
                    <p className="text-xs text-white text-opacity-60 mt-1">{userData.currentXP.toLocaleString()} total</p>
                  </div>

                  {/* Longest Streak */}
                  <div>
                    <p className="text-xs text-white text-opacity-80 font-medium mb-2 flex items-center gap-2 drop-shadow">
                      <Target className="w-4 h-4" />
                      LONGEST STREAK
                    </p>
                    <p className="text-5xl font-bold text-white drop-shadow-lg">24<span className="text-2xl">w</span></p>
                    <p className="text-xs text-white text-opacity-60 mt-1">weeks in a row</p>
                  </div>

                  {/* Current Streak */}
                  <div>
                    <p className="text-xs text-white text-opacity-80 font-medium mb-2 flex items-center gap-2 drop-shadow">
                      <Zap className="w-4 h-4" />
                      CURRENT STREAK
                    </p>
                    <p className="text-5xl font-bold text-white drop-shadow-lg">{currentStreak}<span className="text-2xl">w</span></p>
                    <p className="text-xs text-white text-opacity-60 mt-1">weeks in a row</p>
                  </div>
                </div>
              </div>

              {/* Progress to Next Level */}
              <div>
                <div className="mb-6 p-4 bg-white bg-opacity-10 rounded-lg backdrop-blur border border-white border-opacity-20">
                  <div className="flex justify-between items-center mb-3">
                    <p className="text-sm font-semibold text-white drop-shadow">Progress to Hall of Famer</p>
                    <p className="text-sm text-white text-opacity-70 drop-shadow">{(84000 - userData.currentXP).toLocaleString()} XP to go</p>
                  </div>
                  <div className="w-full bg-white bg-opacity-20 rounded-full h-2.5 overflow-hidden border border-white border-opacity-30">
                    <div
                      className="bg-white bg-opacity-80 h-full rounded-full transition-all duration-300"
                      style={{ width: '57%' }}
                    />
                  </div>
                  <p className="text-xs text-white text-opacity-60 mt-2">57% complete</p>
                </div>

                {/* Quick Achievement Note */}
                <div className="text-center p-3 bg-white bg-opacity-10 rounded-lg border border-white border-opacity-20 backdrop-blur">
                  <p className="text-sm text-white drop-shadow">🔥 <span className="font-semibold">Keep your streak alive!</span></p>
                  <p className="text-xs text-white text-opacity-70">Just 1 more day until week {currentStreak + 1}</p>
                </div>
              </div>
            </div>

            {/* Right: Badge & Level + Extra Stats */}
            <div className="flex flex-col items-center justify-between flex-shrink-0">
              {/* Badge */}
              <div>
                <div className="w-40 h-40 rounded-full bg-white bg-opacity-30 flex items-center justify-center text-7xl font-bold text-white shadow-2xl mb-4 border-2 border-white border-opacity-50 backdrop-blur-sm">
                  🏆
                </div>
                <h2 className="text-3xl font-bold text-white text-center drop-shadow-lg">{userData.currentLevel}</h2>
                <p className="text-white text-opacity-90 text-xs font-medium mt-1 drop-shadow text-center">ACHIEVEMENT LEVEL</p>
              </div>

              {/* Quick Stats Cards */}
              <div className="space-y-2 w-full">
                <div className="bg-white bg-opacity-15 rounded-lg p-3 backdrop-blur border border-white border-opacity-20">
                  <p className="text-xs text-white text-opacity-70">Best Streak</p>
                  <p className="text-2xl font-bold text-white">24w</p>
                </div>
                <div className="bg-white bg-opacity-15 rounded-lg p-3 backdrop-blur border border-white border-opacity-20">
                  <p className="text-xs text-white text-opacity-70">Focus Hours</p>
                  <p className="text-2xl font-bold text-white">147h</p>
                </div>
                <div className="bg-white bg-opacity-15 rounded-lg p-3 backdrop-blur border border-white border-opacity-20">
                  <p className="text-xs text-white text-opacity-70">Levels Unlocked</p>
                  <p className="text-2xl font-bold text-white">6/10</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* PROGRESS TRACKING SECTION */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <BarChart3 className="w-5 h-5 text-blue-600" />
                Focus Hours Progress
              </h3>
            </div>
          </div>

          {/* Target Toggle */}
          <div className="mb-6 flex gap-2">
            <button
              onClick={() => setTargetType('default')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                targetType === 'default'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              FocusHacker Target (800 min)
            </button>
            <button
              onClick={() => setTargetType('personal')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                targetType === 'personal'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Personal Target ({userData.personalTarget} min)
            </button>
          </div>

          {/* Weekly Progress Bar */}
          <div className="mb-8 p-4 bg-slate-50 rounded-lg border border-slate-200">
            <div className="flex justify-between items-baseline mb-3">
              <p className="font-medium text-slate-900">This Week</p>
              <p className="text-sm text-slate-600">
                {userData.currentWeekMinutes} / {currentTarget} minutes
              </p>
            </div>
            <div className="w-full bg-white rounded-full h-4 overflow-hidden border border-slate-200">
              <div
                className={`h-full rounded-full transition-all duration-300 ${
                  targetType === 'default'
                    ? 'bg-gradient-to-r from-blue-400 to-blue-600'
                    : 'bg-gradient-to-r from-purple-400 to-purple-600'
                }`}
                style={{ width: `${(userData.currentWeekMinutes / currentTarget) * 100}%` }}
              />
            </div>
            <p className="text-xs text-slate-500 mt-2">
              {(((userData.currentWeekMinutes / currentTarget) * 100).toFixed(0))}% complete • {currentTarget - userData.currentWeekMinutes} min to go
            </p>
          </div>

          {/* Time Period Selector */}
          <div className="mb-6 flex gap-2">
            {['day', 'week', 'month', 'year'].map((period) => (
              <button
                key={period}
                onClick={() => setTimePeriod(period)}
                className={`px-3 py-2 rounded-lg text-xs font-medium transition-all ${
                  timePeriod === period
                    ? 'bg-slate-900 text-white'
                    : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                }`}
              >
                {period.charAt(0).toUpperCase() + period.slice(1)}
              </button>
            ))}
          </div>

          {/* Chart Area */}
          <div className="border-t border-slate-200 pt-6">
            {timePeriod === 'day' && (
              <div>
                <h4 className="text-sm font-semibold text-slate-900 mb-4">This Week by Day</h4>
                <div className="flex items-end justify-around h-48 gap-2">
                  {dailyData.map((item, idx) => (
                    <div key={idx} className="flex flex-col items-center gap-2 flex-1">
                      <div className="flex items-end justify-center w-full h-32">
                        <div className="w-8 bg-gradient-to-t from-blue-500 to-blue-400 rounded-t"
                             style={{ height: `${(item.minutes / 150) * 100}%` }}
                             title={`${item.minutes} min`}
                        />
                      </div>
                      <p className="text-xs font-medium text-slate-700">{item.day}</p>
                      <p className="text-xs text-slate-500">{item.minutes}m</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {timePeriod === 'week' && (
              <div>
                <h4 className="text-sm font-semibold text-slate-900 mb-6">Last 8 Weeks</h4>
                <div className="flex items-end justify-between h-56 gap-2">
                  {weeklyData.map((item, idx) => (
                    <div key={idx} className="flex flex-col items-center flex-1">
                      <div className="text-xs text-slate-600 mb-2 font-medium">{item.minutes}</div>
                      <div className="flex-grow w-full bg-slate-200 rounded-t overflow-hidden flex items-end justify-center"
                           style={{ minHeight: '8px' }}>
                        <div
                          className={`w-full rounded-t transition-all ${
                            item.hit
                              ? 'bg-gradient-to-t from-green-400 to-green-600'
                              : 'bg-gradient-to-t from-red-400 to-red-600'
                          }`}
                          style={{ height: `${(item.minutes / 1000) * 100}%` }}
                          title={`${item.minutes} min${item.hit ? ' ✓' : ' ✗'}`}
                        />
                      </div>
                      <p className="text-xs font-medium text-slate-700 mt-3">{item.week.replace('Week ', 'W')}</p>
                      <p className="text-lg mt-1">{item.hit ? '✓' : '✗'}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {timePeriod === 'month' && (
              <div className="text-center py-8">
                <BarChart3 className="w-12 h-12 text-slate-300 mx-auto mb-2" />
                <p className="text-slate-500">Monthly view coming soon</p>
              </div>
            )}

            {timePeriod === 'year' && (
              <div className="text-center py-8">
                <BarChart3 className="w-12 h-12 text-slate-300 mx-auto mb-2" />
                <p className="text-slate-500">Yearly view coming soon</p>
              </div>
            )}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-8">
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 text-center">
            <p className="text-2xl font-bold text-green-600">6/10</p>
            <p className="text-xs text-slate-600 mt-1">Levels Unlocked</p>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 text-center">
            <p className="text-2xl font-bold text-purple-600">67%</p>
            <p className="text-xs text-slate-600 mt-1">Weeks Hit Target</p>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 text-center">
            <p className="text-2xl font-bold text-blue-600">24</p>
            <p className="text-xs text-slate-600 mt-1">Best Streak Ever</p>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 text-center">
            <p className="text-2xl font-bold text-indigo-600">147h</p>
            <p className="text-xs text-slate-600 mt-1">Total Focus Hours</p>
          </div>
        </div>
      </div>
    </div>
  );
}
