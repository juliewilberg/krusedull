# Krusedull

A real-time drawing and guessing game for teams. One player draws, everyone else guesses. The game has rounds, scoring, letter hints, custom word lists and private chat for players who have already guessed the word. The in-game text and built-in word list are in Norwegian.

Every player gets a doodle avatar that they can restyle in the lobby. During a round, guessers can send emoji reactions that float over the drawing, and the game plays short sound effects (the speaker button in the header mutes them). These extras are in `index.html` only.

There are two versions:

| File | Runs on | Players need |
|---|---|---|
| `index.html` | GitHub Pages (or any static host) + [Supabase](https://supabase.com) | Just a link and a nickname |
| `krusedull.html` | A claude.ai artifact | A claude.ai account with access to the artifact |

## How to play

1. Open the site and click **Lag et nytt rom** (create a new room). You get a link like `.../#katt-42`.
2. Send the link to your team. Everyone types a nickname and clicks **Bli med** (join).
3. Pick the number of rounds, the drawing time and any custom words, then click **Start spillet**. You need at least two players.

Anyone with the room link can join, so share it only with the people you want to play with.

## Setup (GitHub Pages + Supabase)

You only need to do this once.

### 1. Create the Supabase project

1. Sign up at [supabase.com](https://supabase.com) and create a new project (the free plan is enough).
2. In the project, open **SQL Editor**, click **New query**, paste in the contents of [`supabase/schema.sql`](supabase/schema.sql) and click **Run**.
3. Open **Project Settings → API** and copy the **Project URL** and the **anon public** key.

### 2. Add the keys to the site

Put the two values into [`config.js`](config.js):

```js
window.KRUSEDULL_CONFIG = {
  supabaseUrl: "https://your-project.supabase.co",
  supabaseAnonKey: "your-anon-public-key"
};
```

The anon key is meant to be public, so it is safe to commit. Never put the `service_role` key in this file.

### 3. Turn on GitHub Pages

1. In the GitHub repository, go to **Settings → Pages**.
2. Under **Build and deployment**, choose **Deploy from a branch**, select `main` and `/ (root)`, and save.
3. After a minute the game is live at `https://<your-username>.github.io/krusedull/`.

GitHub Pages on a free GitHub account only works for public repositories. If the repository is private, either make it public or use a paid GitHub plan.

## Good to know

- Players are anonymous. Each browser gets a random player id, stored in `localStorage` together with the nickname.
- The drawer's word never leaves their browser. Other players only receive a hash of it, so guesses are checked without revealing the answer. A determined player could still brute-force the hash against the word list, so this is meant for friendly games.
- Supabase pauses free projects after a week without activity. If the game stops connecting, open the Supabase dashboard and restore the project.
