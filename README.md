# strudel.el

proof-of-concept Strudel mode for Emacs. runs a websocket server through which code is sent to Strudel.

## usage

install, for example using [straight.el](https://github.com/radian-software/straight.el):

```elisp
(use-package strudel
  :straight (strudel :type git :host github :repo "ahihi/strudel.el")
  :config
  ;; set websocket server port (the default is 8080)
  ;; (setq strudel-websocket-port 8080)
  ;; change the highlight function for evaluated code, if you like
  (setq strudel-highlight #'nav-flash-show)
  ;; activate in .strudel files. 
  ;; this assumes you use rjsx-mode as your javascript major mode, modify to taste
  (add-to-list 'auto-mode-alist '("\\.strudel\\'" . rjsx-mode))
  (add-hook 'rjsx-mode-hook #'strudel-mode-if-appropriate)
  ;; define some key bindings
  (define-key strudel-mode-map (kbd "M-<return>") #'strudel-run)
  (define-key strudel-mode-map (kbd "C-c C-s") #'strudel-start)
  (define-key strudel-mode-map (kbd "C-c C-q") #'strudel-stop))
```

open a .strudel file, or do `M-x strudel-mode` manually. then do `M-x strudel-start` (or if using the key bindings above press `C-c C-s`). this starts the websocket server.

in your browser, open Strudel. you will probably need to run a [local build](https://github.com/tidalcycles/strudel/?tab=readme-ov-file#running-locally) (or mess with browser security settings - bad idea) for the browser to allow connecting to the websocket on localhost.

evaluate the following code in the Strudel repl:

```javascript
if(!window.strudelBootstrap) {
  window.strudelBootstrap =  strudelMirror.code;
  const setCode = code => {
    strudelMirror.setCode(window.strudelBootstrap + '\n\n' + code);
  };
  const connect = () => {
    window.strudelWs = new WebSocket('ws://localhost:8080');
    window.strudelWs.addEventListener('open', (event) => {
      setCode('// websocket opened!');
    });
    window.strudelWs.addEventListener('close', (event) => {
      setCode('// websocket closed: ' + event.reason);
    });
    window.strudelWs.addEventListener('error', (event) => {
      setCode('// websocket error!');
    });
    window.strudelWs.addEventListener('message', (event) => {
      setCode(event.data);
      strudelMirror.evaluate();
    });
  };
  connect();
}
console.log(); // need to do something here or we get some AST error
```

if connected successfully, you should now be able to `M-x strudel-run` (or press `M-<return>`) in Emacs to send your buffer contents to Strudel for evaluation!
