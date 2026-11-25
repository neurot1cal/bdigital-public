# Ship your first web app with GitHub and Cloudflare Free

Start with a working temperature converter. Change it on your laptop, preview the change on a phone, then publish it by merging a pull request. You get a public HTTPS address on `pages.dev`. You can do this with free GitHub and Cloudflare accounts and no purchased domain.

Git keeps the history of your files. GitHub hosts that history and runs your checks. Cloudflare Pages publishes the files in `public/`. The app runs in the visitor’s browser. The starter has no package dependencies.

## Start with your coding agent

Open your agent in an empty folder and paste this:

> Read https://raw.githubusercontent.com/neurot1cal/bdigital-public/main/samples/cloudflare-first-app/README.md and follow it with me. First get the sample working locally. Copy only the contents of its starter directory, including .github, into my new app. If this folder already contains an app, inspect it first and adapt the checks and output directory to it. Keep its framework. Use my own GitHub repository and Cloudflare Free account. Walk me through sign-in and the dashboard clicks. Let me make one small change, see its preview, merge it, and verify it on the production URL. Show me how to undo it. Never ask me to paste a password or token into chat.

You can also do the steps yourself. The commands below use Terminal on macOS or Linux, or Git Bash on Windows.

## 1. Get the app running on your laptop

Install [Git](https://git-scm.com/downloads), [Node.js](https://nodejs.org/en/download) (22 or later), and the [GitHub CLI](https://cli.github.com/). Create accounts at [GitHub](https://github.com/) and [Cloudflare](https://dash.cloudflare.com/sign-up). Open a terminal in a folder where you keep projects. Run these commands one line at a time. Choose an unused folder name if either name already exists.

```sh
git clone --depth 1 --filter=blob:none --sparse https://github.com/neurot1cal/bdigital-public.git bdigital-examples
git -C bdigital-examples sparse-checkout set samples/cloudflare-first-app
mkdir my-first-app
cp -R bdigital-examples/samples/cloudflare-first-app/starter/. my-first-app/
cd my-first-app
node --test check.test.mjs
node dev.mjs
```

Open [the app on your laptop](http://127.0.0.1:8080). Enter 100 in Celsius. Fahrenheit should read 212. Press Ctrl+C in the terminal to stop the server. To start it again, run `node dev.mjs` from the app folder.

## 2. Put your own copy on GitHub

In the same folder, run:

```sh
gh auth login
git init -b main
git add -- public/ dev.mjs check.test.mjs .github/workflows/check.yml
git commit -m "Start the web app"
gh repo create my-first-app --private --source=. --remote=origin --push
gh repo view --web
```

For login, choose GitHub.com, HTTPS, and browser sign-in. If Git asks who you are at commit time, set `git config user.name "Your Name"` and `git config user.email "YOUR_GITHUB_NOREPLY_EMAIL"` in this repo, then retry the commit. GitHub shows your private commit email under Settings → Emails. If the repo name is taken in your account, choose another name in the create command.

On GitHub, open **Actions → Check app**. The green check means the pushed commit passed the same tests you ran locally. Keep private keys and credentials outside the repository. Everything published from `public/` is readable by visitors, even when the GitHub repository is private.

## 3. Connect GitHub to Cloudflare Pages once

1. In the Cloudflare dashboard, open **Workers & Pages → Create application**. Choose **Pages** and the **Git / import an existing repository** option. Dashboard wording can vary. The Pages setup asks for a build output directory.
2. Connect GitHub. Give the Cloudflare GitHub app access to your new repository. Choose that repository and a project name.
3. Enter these build settings. Leave the optional root directory empty because you copied the starter files to your repository root.

| Setting | Value |
| --- | --- |
| Production branch | `main` |
| Framework preset | None |
| Build command | `node --test check.test.mjs` |
| Build output directory | `public` |

4. Select **Save and Deploy**. Open the generated HTTPS address shown under Deployments. Type 100 and check for 212 again. Bookmark this address as production.

The Pages build command is a release gate. A failed test exits with an error, so Pages keeps serving the previous successful deployment. GitHub Actions reports the same result on your pull request. The Git integration handles deployments without a Cloudflare API token in GitHub. [Cloudflare static HTML guide](https://developers.cloudflare.com/pages/framework-guides/deploy-anything/) · [GitHub integration](https://developers.cloudflare.com/pages/configuration/git-integration/github-integration/)

## 4. Ship a change through a preview

Run `git switch -c change-heading`. Edit the heading inside `public/index.html` to say “My temperature converter.” Then run:

```sh
node --test check.test.mjs
git add -- public/index.html
git commit -m "Personalize the converter heading"
git push -u origin change-heading
gh pr create --base main --title "Personalize the converter heading" --body "Update the heading on the home page."
gh pr view --web
```

A branch keeps this change separate from production. A pull request (PR) proposes merging it into `main`. Open the Cloudflare preview link on the PR, or find the branch under **Pages → your project → Deployments**. Use branches in your own repository for previews. Confirm the new heading appears on the preview and the old heading still appears on production. Preview URLs are public by default.

Once both checks pass, use **Squash and merge** on GitHub. Return to Cloudflare Deployments and wait for the **production** deployment for the new commit to succeed. Reload the bookmarked production URL and repeat the converter check. A green PR preview alone does not verify production.

```sh
git switch main
git pull --ff-only
```

Repeat this loop for each small change. Add a test whenever the app gains behavior you want to keep. If you add another browser asset, add its path and content type to `dev.mjs` so the local server serves it too.

## 5. Recover from a mistake

- **A check failed.** Open the failed GitHub Actions run or Pages build log. Find the first failing test. Fix it on the same branch, test, commit, and push. The PR and preview update automatically.
- **The site returns 404.** Check the Pages output directory and confirm it contains `index.html`. For this starter, verify the repository contains `public/index.html` directly beneath its root.
- **The wrong version is live.** Compare the commit shown on the Pages production deployment with the latest commit on GitHub’s `main`. Check the production branch setting and open the production URL instead of a preview.
- **A bad change reached production.** Open the merged PR on GitHub, select **Revert**, and merge the resulting revert PR after checks pass. This records the repair in Git. For urgent recovery, use **Pages → Deployments → a previous successful production deployment → Rollback** first. Follow with the Git revert so the next deployment keeps the repair. [Cloudflare rollback guide](https://developers.cloudflare.com/pages/configuration/rollbacks/)

## Where the free tier fits

Pages Free allows 500 builds per month and one concurrent build. Branch previews consume builds too. Static assets are free to serve. Pages Functions and Worker code use separate Workers quotas. GitHub Actions has its own monthly allowance for private repositories. Start with the provided subdomain and check usage before adding server code, storage, or paid services. [Pages limits](https://developers.cloudflare.com/pages/platform/limits/) · [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) · [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)

## Optional paths as your app grows

**Already using a framework?** Keep the same branch and preview loop. For a static Vite app, for example, commit its lockfile, run the project’s existing tests and build command in Pages, and publish its actual output directory (usually `dist`). Run the identical checks in GitHub Actions. A server-rendered framework needs a compatible runtime.

**Want articles, shared navigation, or layouts?** Astro generates HTML from components and content. For a static Astro app, use `npm create astro@latest` in a new directory, keep the default static output, and commit the generated app and lockfile. Run `npm run dev` locally. In Pages, build with `npm run build` and publish `dist`. Once you have tests, run them in the build command before the build. [Astro deployment guide](https://docs.astro.build/en/guides/deploy/cloudflare/)

**Need a backend?** An endpoint that uses a private API key belongs on the server. A small Pages app can add a Pages Function. A standalone Worker or Astro with the Cloudflare adapter also works. Put secrets in the hosting service’s secret settings. Keep public assets and client JavaScript free of credentials. [Pages Functions](https://developers.cloudflare.com/pages/functions/) · [Cloudflare with Astro](https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/)

### How we ship Bdigital

Our tech site uses Astro to generate the article pages at build time. Routes that need a live request opt into server rendering. The Cloudflare adapter produces static files in `dist/client/` and Worker code and deployment configuration in `dist/server/`.

Our GitHub Actions workflow builds the tech site and runs the full suite on pull requests. A push to `main` rebuilds it, generates the résumé downloads, and runs a smaller security suite before deployment. The deploy step invokes the project’s Wrangler CLI using the adapter-generated configuration. After deployment we check the live custom domain. Our production Workers disable public Worker and preview hostnames because those projects have their own access controls.

If you choose that architecture, install the supported adapter (`npx astro add cloudflare` in an Astro app), run a build, and verify the generated configuration before your first deploy. In GitHub Actions, expose an account-scoped Worker deploy token only to the main-branch deploy step. Set `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from your own repository secrets. Follow the current adapter instructions for the deployment command. Use one production deploy mechanism per app to avoid competing releases. [Cloudflare deployment with GitHub Actions](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)

The reusable part is the loop you just practiced: version a small change, test it, review a preview, merge, and verify the live result.
