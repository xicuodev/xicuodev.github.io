// 代码块按钮监听器（结构见 layouts/_default/_markup/render-codeblock.html）。
document.addEventListener('click', (event) => {
  const btn = event.target.closest('.code-block .code-btn');
  if (!btn) return;
  const block = btn.closest('.code-block');

  if (btn.dataset.action === 'wrap') {
    btn.setAttribute('aria-pressed', block.classList.toggle('is-wrapped'));
    return;
  }

  const flash = (label) => {
    clearTimeout(btn.resetTimer);
    btn.textContent = label;
    btn.resetTimer = setTimeout(() => { btn.textContent = '复制'; }, 1500);
  };
  const text = [...block.querySelectorAll('.cl')].map((cl) => cl.textContent).join('');
  Promise.resolve()
    .then(() => navigator.clipboard.writeText(text))
    .then(() => flash('已复制'), () => flash('复制失败'));
});
