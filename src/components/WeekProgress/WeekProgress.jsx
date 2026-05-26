import React from 'react';
import styles from './weekProgress.module.css';

function goalPercent({ completed, total }) {
  if (!total || total <= 0) return 0;
  return Math.round((completed / total) * 100);
}

function minutesRemaining({ completed, total }) {
  return Math.max(0, total - completed);
}

function GoalRow({ title, completed, total, variant }) {
  const percent = goalPercent({ completed, total });
  const remaining = minutesRemaining({ completed, total });
  const width = Math.min(100, Math.max(0, percent));
  const rowClass = variant === 'hero' ? styles.hackerGoal : styles.personalGoal;

  return (
    <div className={rowClass}>
      <div className={styles.goalHeader}>
        <span className={styles.goalTitle}>{title}</span>
        <div className={styles.goalMetaGroup}>
          <span className={styles.goalPercent}>{percent}%</span>
          <span className={styles.goalRemaining}>{remaining} min to go</span>
        </div>
      </div>
      <div
        className={styles.progressBar}
        role="progressbar"
        aria-valuenow={completed}
        aria-valuemin={0}
        aria-valuemax={total}
        aria-label={`${title}: ${remaining} minutes to go, ${percent} percent`}
      >
        <div className={styles.progressFill} style={{ width: `${width}%` }} />
      </div>
    </div>
  );
}

export function WeekProgress({
  focusMinutes = 51,
  hackerGoal = { completed: 51, total: 800 },
  personalGoal = { completed: 51, total: 780 },
  weekStreak = 0,
}) {
  return (
    <section className={styles.container} aria-label="Current week progress">
      <div className={styles.layout}>
        <div className={styles.mainPanel}>
          <p className={styles.sectionHeader}>Focus time this week</p>

          <div className={styles.focusMetric}>
            <p className={styles.focusMetricLabel}>Focus hours so far this week</p>
            <p className={styles.focusMetricValue}>
              <span className={styles.focusMinutes}>{focusMinutes}</span>
              <span className={styles.focusUnit}>min</span>
            </p>
          </div>

          <p className={styles.sectionHeader}>Progress towards goals</p>

          <div className={styles.goalsStack}>
            <GoalRow
              title="Hacker Goal"
              completed={hackerGoal.completed}
              total={hackerGoal.total}
              variant="hero"
            />
            <GoalRow
              title="Personal Goal"
              completed={personalGoal.completed}
              total={personalGoal.total}
              variant="subtle"
            />
          </div>
        </div>

        <div className={styles.divider} aria-hidden="true" />

        <aside className={styles.streakPanel}>
          <p className={styles.streakHeader}>Week streak</p>
          <div className={styles.streakCircle} aria-label={`${weekStreak} weeks`}>
            <span className={styles.streakNumber}>{weekStreak}</span>
          </div>
          <p className={styles.streakExplainer}>Weeks in a row hitting your goals</p>
        </aside>
      </div>
    </section>
  );
}

export default WeekProgress;
