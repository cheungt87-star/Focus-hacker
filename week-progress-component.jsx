export default function WeekProgress() {
  const focusMinutes = 51;
  const hackerGoal = 800;
  const personalGoal = 780;
  const hackerRemaining = hackerGoal - focusMinutes;
  const personalRemaining = personalGoal - focusMinutes;
  const hackerPercentage = (focusMinutes / hackerGoal) * 100;
  const personalPercentage = (focusMinutes / personalGoal) * 100;

  return (
    <div className="flex rounded-lg border border-gray-200 bg-white overflow-hidden">
      {/* Left Section: Focus Time */}
      <div className="flex-1 p-8 border-r border-gray-200">
        <h3 className="text-xs font-medium text-gray-500 mb-7 uppercase tracking-wider">
          Focus time this week
        </h3>

        <div className="mb-7">
          <p className="text-xs text-gray-400 mb-1.5 uppercase tracking-wider">Focus hours so far this week</p>
          <div className="flex items-baseline gap-1.5">
            <span className="text-3xl font-medium text-gray-900">{focusMinutes}</span>
            <span className="text-sm text-gray-600">min</span>
          </div>
        </div>

        <h4 className="text-xs font-medium text-gray-500 mb-7 uppercase tracking-wider">
          Progress towards goals
        </h4>

        <div className="space-y-10">
          {/* Hacker Goal - HERO */}
          <div>
            <div className="flex justify-between items-center mb-4">
              <p className="text-base font-medium text-gray-900">Hacker Goal</p>
              <div className="flex items-center gap-2">
                <p className="text-xs text-gray-400">{Math.round(hackerPercentage)}%</p>
                <p className="text-sm font-semibold text-gray-900">{hackerRemaining} min to go</p>
              </div>
            </div>
            <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-600 rounded-full transition-all"
                style={{
                  width: `${hackerPercentage}%`,
                }}
              />
            </div>
          </div>

          {/* Personal Goal - SUBTLE */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <p className="text-sm font-normal text-gray-600">Personal Goal</p>
              <div className="flex items-center gap-2">
                <p className="text-xs text-gray-400">{Math.round(personalPercentage)}%</p>
                <p className="text-xs font-normal text-gray-600">{personalRemaining} min to go</p>
              </div>
            </div>
            <div className="w-full h-1 bg-gray-100 rounded-full overflow-hidden">
              <div
                className="h-full rounded-full transition-all"
                style={{
                  width: `${personalPercentage}%`,
                  backgroundColor: '#e9d5ff',
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Right Section: Streak */}
      <div className="flex-shrink-0 w-56 p-8 flex flex-col items-center justify-center text-center bg-gray-50">
        <p className="text-xs font-semibold text-gray-500 mb-6 uppercase tracking-widest">
          Week streak
        </p>

        <div className="w-28 h-28 rounded-full bg-amber-400 flex items-center justify-center mb-5 flex-shrink-0 border-2 border-amber-500">
          <span className="text-5xl font-medium text-white">0</span>
        </div>

        <p className="text-xs text-gray-600 leading-relaxed">
          Weeks in a row hitting your goals
        </p>
      </div>
    </div>
  );
}
