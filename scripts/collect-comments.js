// Saves the previous AI review and other participants' comments into pr-comments/.
// Env: INCLUDE_PREVIOUS, INCLUDE_COMMENTS, COMMENT_MARKER
module.exports = async ({ github, context, core }) => {
  const fs = require('fs');
  const path = require('path');

  const marker = process.env.COMMENT_MARKER || '<!-- ai-code-review -->';
  const includePrevious = process.env.INCLUDE_PREVIOUS !== 'false';
  const includeComments = process.env.INCLUDE_COMMENTS !== 'false';

  const { owner, repo } = context.repo;
  const issue_number = context.issue.number;

  const baseDir = 'pr-comments';
  const othersDir = path.join(baseDir, 'others');
  fs.mkdirSync(othersDir, { recursive: true });

  const issueComments = await github.paginate(github.rest.issues.listComments, {
    owner, repo, issue_number, per_page: 100,
  });

  const ourComments = issueComments.filter(c => c.body && c.body.includes(marker));
  if (includePrevious && ourComments.length > 0) {
    const last = ourComments[ourComments.length - 1];
    fs.writeFileSync(path.join(baseDir, 'previous_ai_review.md'), last.body || '');
    core.info(`Saved previous AI review (comment #${last.id}).`);
  }

  if (includeComments) {
    let idx = 0;
    const dump = (kind, author, when, extra, body) => {
      const safeAuthor = String(author || 'unknown').replace(/[^a-zA-Z0-9._-]/g, '_');
      const name = `${String(idx).padStart(3, '0')}_${kind}_${safeAuthor}.md`;
      const header = `Author: ${author}\nDate: ${when || '?'}\nType: ${kind}${extra ? ` (${extra})` : ''}\n\n`;
      fs.writeFileSync(path.join(othersDir, name), header + (body || ''));
      idx++;
    };

    for (const c of issueComments) {
      if (c.body && c.body.includes(marker)) continue;
      dump('conversation', c.user && c.user.login, c.created_at, null, c.body);
    }

    const reviews = await github.paginate(github.rest.pulls.listReviews, {
      owner, repo, pull_number: issue_number, per_page: 100,
    });
    for (const r of reviews) {
      if (!r.body) continue;
      dump('review', r.user && r.user.login, r.submitted_at, r.state, r.body);
    }

    const reviewComments = await github.paginate(github.rest.pulls.listReviewComments, {
      owner, repo, pull_number: issue_number, per_page: 100,
    });
    for (const c of reviewComments) {
      const loc = `${c.path}:${c.line ?? c.original_line ?? '?'}`;
      dump('inline', c.user && c.user.login, c.created_at, loc, c.body);
    }

    core.info(`Saved ${idx} other comment file(s) to ${othersDir}/`);
  }
};
