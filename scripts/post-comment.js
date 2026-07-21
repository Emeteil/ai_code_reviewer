// Posts the review as a PR comment, or updates the existing one.
// Env: AI_REVIEW_TITLE, AI_REVIEW_MODEL, AI_REVIEW_COMMENT_MODE, COMMENT_MARKER,
//      SNIPPETS_DIR, GITHUB_ACTION_PATH
module.exports = async ({ github, context, core }) => {
  const fs = require('fs');
  const path = require('path');

  const loadSnippet = (name) => {
    const custom = process.env.SNIPPETS_DIR
      ? path.join(process.env.SNIPPETS_DIR, name)
      : null;
    const bundled = path.join(process.env.GITHUB_ACTION_PATH, 'prompts', 'snippets', name);
    const file = (custom && fs.existsSync(custom)) ? custom : bundled;
    return fs.readFileSync(file, 'utf8').trim();
  };

  const marker = process.env.COMMENT_MARKER || '<!-- ai-code-review -->';
  const title = process.env.AI_REVIEW_TITLE;
  const model = process.env.AI_REVIEW_MODEL;
  const commentMode = process.env.AI_REVIEW_COMMENT_MODE;

  let review = '';
  try { review = fs.readFileSync('review.md', 'utf8').trim(); } catch (e) {}
  if (!review) {
    review = loadSnippet('no-response.md');
  }

  const footer = loadSnippet('comment-footer.md').split('{{MODEL}}').join(model);
  const body = `${marker}\n## ${title}\n\n${review}\n\n${footer}`;

  const { owner, repo } = context.repo;
  const issue_number = context.issue.number;

  let existing = null;
  if (commentMode !== 'create') {
    const comments = await github.paginate(github.rest.issues.listComments, {
      owner, repo, issue_number, per_page: 100,
    });
    existing = comments.find(c => c.body && c.body.includes(marker));
  }

  if (existing) {
    await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body });
    core.info(`Updated existing review comment #${existing.id}`);
  } else {
    const created = await github.rest.issues.createComment({ owner, repo, issue_number, body });
    core.info(`Created new review comment #${created.data.id}`);
  }
};
