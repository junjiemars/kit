<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>gud.el</title>
<style type="text/css">
.enscript-comment { font-style: italic; color: rgb(178,34,34); }
.enscript-function-name { font-weight: bold; color: rgb(0,0,255); }
.enscript-variable-name { font-weight: bold; color: rgb(184,134,11); }
.enscript-keyword { font-weight: bold; color: rgb(160,32,240); }
.enscript-reference { font-weight: bold; color: rgb(95,158,160); }
.enscript-string { font-weight: bold; color: rgb(188,143,143); }
.enscript-builtin { font-weight: bold; color: rgb(218,112,214); }
.enscript-type { font-weight: bold; color: rgb(34,139,34); }
.enscript-highlight { text-decoration: underline; color: 0; }
</style>
</head>
<body id="top">
<h1 style="margin:8px;" id="f1">gud.el&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
<hr/>
<div></div>
<pre>
<span class="enscript-comment">;;; gud.el --- Grand Unified Debugger mode for running GDB and other debuggers
</span>
<span class="enscript-comment">;; Author: Eric S. Raymond &lt;<a href="mailto:esr@snark.thyrsus.com">esr@snark.thyrsus.com</a>&gt;
</span><span class="enscript-comment">;; Maintainer: FSF
</span><span class="enscript-comment">;; Keywords: unix, tools
</span>
<span class="enscript-comment">;; Copyright (C) 1992, 1993, 1994, 1995, 1996, 1998, 2000, 2001, 2002, 2003,
</span><span class="enscript-comment">;;  2004, 2005, 2006, 2007, 2008 Free Software Foundation, Inc.
</span>
<span class="enscript-comment">;; This file is part of GNU Emacs.
</span>
<span class="enscript-comment">;; GNU Emacs is free software; you can redistribute it and/or modify
</span><span class="enscript-comment">;; it under the terms of the GNU General Public License as published by
</span><span class="enscript-comment">;; the Free Software Foundation; either version 3, or (at your option)
</span><span class="enscript-comment">;; any later version.
</span>
<span class="enscript-comment">;; GNU Emacs is distributed in the hope that it will be useful,
</span><span class="enscript-comment">;; but WITHOUT ANY WARRANTY; without even the implied warranty of
</span><span class="enscript-comment">;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
</span><span class="enscript-comment">;; GNU General Public License for more details.
</span>
<span class="enscript-comment">;; You should have received a copy of the GNU General Public License
</span><span class="enscript-comment">;; along with GNU Emacs; see the file COPYING.  If not, write to the
</span><span class="enscript-comment">;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
</span><span class="enscript-comment">;; Boston, MA 02110-1301, USA.
</span>
<span class="enscript-comment">;;; Commentary:
</span>
<span class="enscript-comment">;; The ancestral gdb.el was by W. Schelter &lt;<a href="mailto:wfs@rascal.ics.utexas.edu">wfs@rascal.ics.utexas.edu</a>&gt; It was
</span><span class="enscript-comment">;; later rewritten by rms.  Some ideas were due to Masanobu.  Grand
</span><span class="enscript-comment">;; Unification (sdb/dbx support) by Eric S. Raymond &lt;<a href="mailto:esr@thyrsus.com">esr@thyrsus.com</a>&gt; Barry
</span><span class="enscript-comment">;; Warsaw &lt;<a href="mailto:bwarsaw@cen.com">bwarsaw@cen.com</a>&gt; hacked the mode to use comint.el.  Shane Hartman
</span><span class="enscript-comment">;; &lt;<a href="mailto:shane@spr.com">shane@spr.com</a>&gt; added support for xdb (HPUX debugger).  Rick Sladkey
</span><span class="enscript-comment">;; &lt;<a href="mailto:jrs@world.std.com">jrs@world.std.com</a>&gt; wrote the GDB command completion code.  Dave Love
</span><span class="enscript-comment">;; &lt;<a href="mailto:d.love@dl.ac.uk">d.love@dl.ac.uk</a>&gt; added the IRIX kluge, re-implemented the Mips-ish variant
</span><span class="enscript-comment">;; and added a menu. Brian D. Carlstrom &lt;<a href="mailto:bdc@ai.mit.edu">bdc@ai.mit.edu</a>&gt; combined the IRIX
</span><span class="enscript-comment">;; kluge with the gud-xdb-directories hack producing gud-dbx-directories.
</span><span class="enscript-comment">;; Derek L. Davies &lt;<a href="mailto:ddavies@world.std.com">ddavies@world.std.com</a>&gt; added support for jdb (Java
</span><span class="enscript-comment">;; debugger.)
</span>
<span class="enscript-comment">;;; Code:
</span>
(<span class="enscript-keyword">eval-when-compile</span> (require 'cl)) <span class="enscript-comment">; for case macro
</span>
(require 'comint)

(defvar gdb-active-process)
(defvar gdb-define-alist)
(defvar gdb-macro-info)
(defvar gdb-server-prefix)
(defvar gdb-show-changed-values)
(defvar gdb-var-list)
(defvar gdb-speedbar-auto-raise)
(defvar tool-bar-map)

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; GUD commands must be visible in C buffers visited by GUD
</span>
(defgroup gud nil
  <span class="enscript-string">&quot;Grand Unified Debugger mode for gdb and other debuggers under Emacs.
Supported debuggers include gdb, sdb, dbx, xdb, perldb, pdb (Python) and jdb.&quot;</span>
  <span class="enscript-reference">:group</span> 'unix
  <span class="enscript-reference">:group</span> 'tools)


(defcustom gud-key-prefix <span class="enscript-string">&quot;\C-x\C-a&quot;</span>
  <span class="enscript-string">&quot;Prefix of all GUD commands valid in C buffers.&quot;</span>
  <span class="enscript-reference">:type</span> 'string
  <span class="enscript-reference">:group</span> 'gud)

(global-set-key (concat gud-key-prefix <span class="enscript-string">&quot;\C-l&quot;</span>) 'gud-refresh)
(define-key ctl-x-map <span class="enscript-string">&quot; &quot;</span> 'gud-break)	<span class="enscript-comment">;; backward compatibility hack
</span>
(defvar gud-marker-filter nil)
(put 'gud-marker-filter 'permanent-local t)
(defvar gud-find-file nil)
(put 'gud-find-file 'permanent-local t)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-marker-filter</span> (&amp;rest args)
  (apply gud-marker-filter args))

(defvar gud-minor-mode nil)
(put 'gud-minor-mode 'permanent-local t)

(defvar gud-comint-buffer nil)

(defvar gud-keep-buffer nil)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-symbol</span> (sym &amp;optional soft minor-mode)
  <span class="enscript-string">&quot;Return the symbol used for SYM in MINOR-MODE.
MINOR-MODE defaults to `gud-minor-mode'.
The symbol returned is `gud-&lt;MINOR-MODE&gt;-&lt;SYM&gt;'.
If SOFT is non-nil, returns nil if the symbol doesn't already exist.&quot;</span>
  (<span class="enscript-keyword">unless</span> (<span class="enscript-keyword">or</span> minor-mode gud-minor-mode) (error <span class="enscript-string">&quot;Gud internal error&quot;</span>))
  (funcall (<span class="enscript-keyword">if</span> soft 'intern-soft 'intern)
	   (format <span class="enscript-string">&quot;gud-%s-%s&quot;</span> (<span class="enscript-keyword">or</span> minor-mode gud-minor-mode) sym)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-val</span> (sym &amp;optional minor-mode)
  <span class="enscript-string">&quot;Return the value of `gud-symbol' SYM.  Default to nil.&quot;</span>
  (<span class="enscript-keyword">let</span> ((sym (gud-symbol sym t minor-mode)))
    (<span class="enscript-keyword">if</span> (boundp sym) (symbol-value sym))))

(defvar gud-running nil
  <span class="enscript-string">&quot;Non-nil if debugged program is running.
Used to grey out relevant toolbar icons.&quot;</span>)

(defvar gdb-ready nil)

<span class="enscript-comment">;; Use existing Info buffer, if possible.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-goto-info</span> ()
  <span class="enscript-string">&quot;Go to relevant Emacs info node.&quot;</span>
  (interactive)
  (<span class="enscript-keyword">let</span> ((same-window-regexps same-window-regexps)
	(display-buffer-reuse-frames t))
    (<span class="enscript-keyword">catch</span> 'info-found
      (walk-windows
       '(<span class="enscript-keyword">lambda</span> (window)
	  (<span class="enscript-keyword">if</span> (eq (window-buffer window) (get-buffer <span class="enscript-string">&quot;*info*&quot;</span>))
	      (<span class="enscript-keyword">progn</span>
		(setq same-window-regexps nil)
		(<span class="enscript-keyword">throw</span> 'info-found nil))))
       nil 0)
      (select-frame (make-frame)))
    (<span class="enscript-keyword">if</span> (memq gud-minor-mode '(gdbmi gdba))
	(info <span class="enscript-string">&quot;(emacs)GDB Graphical Interface&quot;</span>)
      (info <span class="enscript-string">&quot;(emacs)Debuggers&quot;</span>))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tool-bar-item-visible-no-fringe</span> ()
  (not (<span class="enscript-keyword">or</span> (eq (buffer-local-value 'major-mode (window-buffer)) 'speedbar-mode)
	   (<span class="enscript-keyword">and</span> (memq gud-minor-mode '(gdbmi gdba))
		(&gt; (car (window-fringes)) 0)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-stop-subjob</span> ()
  (interactive)
  (with-current-buffer gud-comint-buffer
    (<span class="enscript-keyword">if</span> (string-equal gud-target-name <span class="enscript-string">&quot;emacs&quot;</span>)
	(comint-stop-subjob)
      (comint-interrupt-subjob))))

(easy-mmode-defmap gud-menu-map
  '(([help]     <span class="enscript-string">&quot;Info&quot;</span> . gud-goto-info)
    ([tooltips] menu-item <span class="enscript-string">&quot;Show GUD tooltips&quot;</span> gud-tooltip-mode
                  <span class="enscript-reference">:enable</span> (<span class="enscript-keyword">and</span> (not emacs-basic-display)
			       (display-graphic-p)
			       (fboundp 'x-show-tip))
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode
				'(lldb gdbmi gdba dbx sdb xdb pdb))
	          <span class="enscript-reference">:button</span> (:toggle . gud-tooltip-mode))
    ([refresh]	<span class="enscript-string">&quot;Refresh&quot;</span> . gud-refresh)
    ([run]	menu-item <span class="enscript-string">&quot;Run&quot;</span> gud-run
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(lldb gdbmi gdb dbx jdb)))
    ([go]	menu-item (<span class="enscript-keyword">if</span> gdb-active-process <span class="enscript-string">&quot;Continue&quot;</span> <span class="enscript-string">&quot;Run&quot;</span>) gud-go
		  <span class="enscript-reference">:visible</span> (<span class="enscript-keyword">and</span> (not gud-running)
				(eq gud-minor-mode 'gdba)))
    ([stop]	menu-item <span class="enscript-string">&quot;Stop&quot;</span> gud-stop-subjob
		  <span class="enscript-reference">:visible</span> (<span class="enscript-keyword">or</span> (not (memq gud-minor-mode '(gdba pdb)))
			       (<span class="enscript-keyword">and</span> gud-running
				    (eq gud-minor-mode 'gdba))))
    ([until]	menu-item <span class="enscript-string">&quot;Continue to selection&quot;</span> gud-until
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (<span class="enscript-keyword">and</span> (memq gud-minor-mode '(gdbmi gdba gdb perldb))
				(gud-tool-bar-item-visible-no-fringe)))
    ([remove]	menu-item <span class="enscript-string">&quot;Remove Breakpoint&quot;</span> gud-remove
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (gud-tool-bar-item-visible-no-fringe))
    ([tbreak]	menu-item <span class="enscript-string">&quot;Temporary Breakpoint&quot;</span> gud-tbreak
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode
				'(lldb gdbmi gdba gdb sdb xdb)))
    ([break]	menu-item <span class="enscript-string">&quot;Set Breakpoint&quot;</span> gud-break
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (gud-tool-bar-item-visible-no-fringe))
    ([up]	menu-item <span class="enscript-string">&quot;Up Stack&quot;</span> gud-up
		  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode
				 '(lldb gdbmi gdba gdb dbx xdb jdb pdb)))
    ([down]	menu-item <span class="enscript-string">&quot;Down Stack&quot;</span> gud-down
		  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode
				 '(lldb gdbmi gdba gdb dbx xdb jdb pdb)))
    ([pp]	menu-item <span class="enscript-string">&quot;Print S-expression&quot;</span> gud-pp
                  <span class="enscript-reference">:enable</span> (<span class="enscript-keyword">and</span> (not gud-running)
				  gdb-active-process)
		  <span class="enscript-reference">:visible</span> (<span class="enscript-keyword">and</span> (string-equal
				 (buffer-local-value
				  'gud-target-name gud-comint-buffer) <span class="enscript-string">&quot;emacs&quot;</span>)
				(eq gud-minor-mode 'gdba)))
    ([print*]	menu-item <span class="enscript-string">&quot;Print Dereference&quot;</span> gud-pstar
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(lldb gdbmi gdba gdb)))
    ([print]	menu-item <span class="enscript-string">&quot;Print Expression&quot;</span> gud-print
                  <span class="enscript-reference">:enable</span> (not gud-running))
    ([watch]	menu-item <span class="enscript-string">&quot;Watch Expression&quot;</span> gud-watch
		  <span class="enscript-reference">:enable</span> (not gud-running)
	  	  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(gdbmi gdba)))
    ([finish]	menu-item <span class="enscript-string">&quot;Finish Function&quot;</span> gud-finish
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode
				 '(lldb gdbmi gdba gdb xdb jdb pdb)))
    ([stepi]	menu-item <span class="enscript-string">&quot;Step Instruction&quot;</span> gud-stepi
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(lldb gdbmi gdba gdb dbx)))
    ([nexti]	menu-item <span class="enscript-string">&quot;Next Instruction&quot;</span> gud-nexti
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(lldb gdbmi gdba gdb dbx)))
    ([step]	menu-item <span class="enscript-string">&quot;Step Line&quot;</span> gud-step
                  <span class="enscript-reference">:enable</span> (not gud-running))
    ([next]	menu-item <span class="enscript-string">&quot;Next Line&quot;</span> gud-next
                  <span class="enscript-reference">:enable</span> (not gud-running))
    ([cont]	menu-item <span class="enscript-string">&quot;Continue&quot;</span> gud-cont
                  <span class="enscript-reference">:enable</span> (not gud-running)
		  <span class="enscript-reference">:visible</span> (not (eq gud-minor-mode 'gdba))))
  <span class="enscript-string">&quot;Menu for `gud-mode'.&quot;</span>
  <span class="enscript-reference">:name</span> <span class="enscript-string">&quot;Gud&quot;</span>)

(easy-mmode-defmap gud-minor-mode-map
  (append
     `(([menu-bar debug] . (<span class="enscript-string">&quot;Gud&quot;</span> . ,gud-menu-map)))
     <span class="enscript-comment">;; Get tool bar like functionality from the menu bar on a text only
</span>     <span class="enscript-comment">;; terminal.
</span>   (<span class="enscript-keyword">unless</span> window-system
     `(([menu-bar down]
	. (,(propertize <span class="enscript-string">&quot;down&quot;</span> 'face 'font-lock-doc-face) . gud-down))
       ([menu-bar up]
	. (,(propertize <span class="enscript-string">&quot;up&quot;</span> 'face 'font-lock-doc-face) . gud-up))
       ([menu-bar finish]
	. (,(propertize <span class="enscript-string">&quot;finish&quot;</span> 'face 'font-lock-doc-face) . gud-finish))
       ([menu-bar step]
	. (,(propertize <span class="enscript-string">&quot;step&quot;</span> 'face 'font-lock-doc-face) . gud-step))
       ([menu-bar next]
	. (,(propertize <span class="enscript-string">&quot;next&quot;</span> 'face 'font-lock-doc-face) . gud-next))
       ([menu-bar until] menu-item
	,(propertize <span class="enscript-string">&quot;until&quot;</span> 'face 'font-lock-doc-face) gud-until
		  <span class="enscript-reference">:visible</span> (memq gud-minor-mode '(gdbmi gdba gdb perldb)))
       ([menu-bar cont] menu-item
	,(propertize <span class="enscript-string">&quot;cont&quot;</span> 'face 'font-lock-doc-face) gud-cont
	<span class="enscript-reference">:visible</span> (not (eq gud-minor-mode 'gdba)))
       ([menu-bar run] menu-item
	,(propertize <span class="enscript-string">&quot;run&quot;</span> 'face 'font-lock-doc-face) gud-run
	<span class="enscript-reference">:visible</span> (memq gud-minor-mode '(gdbmi gdb dbx jdb)))
       ([menu-bar go] menu-item
	,(propertize <span class="enscript-string">&quot; go &quot;</span> 'face 'font-lock-doc-face) gud-go
	<span class="enscript-reference">:visible</span> (<span class="enscript-keyword">and</span> (not gud-running)
		      (eq gud-minor-mode 'gdba)))
       ([menu-bar stop] menu-item
	,(propertize <span class="enscript-string">&quot;stop&quot;</span> 'face 'font-lock-doc-face) gud-stop-subjob
	<span class="enscript-reference">:visible</span> (<span class="enscript-keyword">or</span> gud-running
		     (not (eq gud-minor-mode 'gdba))))
       ([menu-bar print]
	. (,(propertize <span class="enscript-string">&quot;print&quot;</span> 'face 'font-lock-doc-face) . gud-print))
       ([menu-bar tools] . undefined)
       ([menu-bar buffer] . undefined)
       ([menu-bar options] . undefined)
       ([menu-bar edit] . undefined)
       ([menu-bar file] . undefined))))
  <span class="enscript-string">&quot;Map used in visited files.&quot;</span>)

(<span class="enscript-keyword">let</span> ((m (assq 'gud-minor-mode minor-mode-map-alist)))
  (<span class="enscript-keyword">if</span> m (setcdr m gud-minor-mode-map)
    (push (cons 'gud-minor-mode gud-minor-mode-map) minor-mode-map-alist)))

(defvar gud-mode-map
  <span class="enscript-comment">;; Will inherit from comint-mode via define-derived-mode.
</span>  (make-sparse-keymap)
  <span class="enscript-string">&quot;`gud-mode' keymap.&quot;</span>)

(defvar gud-tool-bar-map
  (<span class="enscript-keyword">if</span> (display-graphic-p)
      (<span class="enscript-keyword">let</span> ((map (make-sparse-keymap)))
	(dolist (x '((gud-break . <span class="enscript-string">&quot;gud/break&quot;</span>)
		     (gud-remove . <span class="enscript-string">&quot;gud/remove&quot;</span>)
		     (gud-print . <span class="enscript-string">&quot;gud/print&quot;</span>)
		     (gud-pstar . <span class="enscript-string">&quot;gud/pstar&quot;</span>)
		     (gud-pp . <span class="enscript-string">&quot;gud/pp&quot;</span>)
		     (gud-watch . <span class="enscript-string">&quot;gud/watch&quot;</span>)
		     (gud-run . <span class="enscript-string">&quot;gud/run&quot;</span>)
		     (gud-go . <span class="enscript-string">&quot;gud/go&quot;</span>)
		     (gud-stop-subjob . <span class="enscript-string">&quot;gud/stop&quot;</span>)
		     (gud-cont . <span class="enscript-string">&quot;gud/cont&quot;</span>)
		     (gud-until . <span class="enscript-string">&quot;gud/until&quot;</span>)
		     (gud-next . <span class="enscript-string">&quot;gud/next&quot;</span>)
		     (gud-step . <span class="enscript-string">&quot;gud/step&quot;</span>)
		     (gud-finish . <span class="enscript-string">&quot;gud/finish&quot;</span>)
		     (gud-nexti . <span class="enscript-string">&quot;gud/nexti&quot;</span>)
		     (gud-stepi . <span class="enscript-string">&quot;gud/stepi&quot;</span>)
		     (gud-up . <span class="enscript-string">&quot;gud/up&quot;</span>)
		     (gud-down . <span class="enscript-string">&quot;gud/down&quot;</span>)
		     (gud-goto-info . <span class="enscript-string">&quot;info&quot;</span>))
		   map)
	  (tool-bar-local-item-from-menu
	   (car x) (cdr x) map gud-minor-mode-map)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-file-name</span> (f)
  <span class="enscript-string">&quot;Transform a relative file name to an absolute file name.
Uses `gud-&lt;MINOR-MODE&gt;-directories' to find the source files.&quot;</span>
  (<span class="enscript-keyword">if</span> (file-exists-p f) (expand-file-name f)
    (<span class="enscript-keyword">let</span> ((directories (gud-val 'directories))
	  (result nil))
      (<span class="enscript-keyword">while</span> directories
	(<span class="enscript-keyword">let</span> ((path (expand-file-name f (car directories))))
	  (<span class="enscript-keyword">if</span> (file-exists-p path)
	      (setq result path
		    directories nil)))
	(setq directories (cdr directories)))
      result)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-find-file</span> (file)
  <span class="enscript-comment">;; Don't get confused by double slashes in the name that comes from GDB.
</span>  (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;//+&quot;</span> file)
    (setq file (replace-match <span class="enscript-string">&quot;/&quot;</span> t t file)))
  (<span class="enscript-keyword">let</span> ((minor-mode gud-minor-mode)
	(buf (funcall (<span class="enscript-keyword">or</span> gud-find-file 'gud-file-name) file)))
    (<span class="enscript-keyword">when</span> (stringp buf)
      (setq buf (<span class="enscript-keyword">and</span> (file-readable-p buf) (find-file-noselect buf 'nowarn))))
    (<span class="enscript-keyword">when</span> buf
      <span class="enscript-comment">;; Copy `gud-minor-mode' to the found buffer to turn on the menu.
</span>      (with-current-buffer buf
	(set (make-local-variable 'gud-minor-mode) minor-mode)
	(set (make-local-variable 'tool-bar-map) gud-tool-bar-map)
	(<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> gud-tooltip-mode
		   (memq gud-minor-mode '(gdbmi gdba)))
	  (make-local-variable 'gdb-define-alist)
	  (<span class="enscript-keyword">unless</span>  gdb-define-alist (gdb-create-define-alist))
	  (add-hook 'after-save-hook 'gdb-create-define-alist nil t))
	(make-local-variable 'gud-keep-buffer))
      buf)))

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; command definition
</span>
<span class="enscript-comment">;; This macro is used below to define some basic debugger interface commands.
</span><span class="enscript-comment">;; Of course you may use `gud-def' with any other debugger command, including
</span><span class="enscript-comment">;; user defined ones.
</span>
<span class="enscript-comment">;; A macro call like (gud-def FUNC CMD KEY DOC) expands to a form
</span><span class="enscript-comment">;; which defines FUNC to send the command CMD to the debugger, gives
</span><span class="enscript-comment">;; it the docstring DOC, and binds that function to KEY in the GUD
</span><span class="enscript-comment">;; major mode.  The function is also bound in the global keymap with the
</span><span class="enscript-comment">;; GUD prefix.
</span>
(defmacro gud-def (func cmd key &amp;optional doc)
  <span class="enscript-string">&quot;Define FUNC to be a command sending CMD and bound to KEY, with
optional doc string DOC.  Certain %-escapes in the string arguments
are interpreted specially if present.  These are:

  %f -- Name (without directory) of current source file.
  %F -- Name (without directory or extension) of current source file.
  %d -- Directory of current source file.
  %l -- Number of current source line.
  %e -- Text of the C lvalue or function-call expression surrounding point.
  %a -- Text of the hexadecimal address surrounding point.
  %b -- Text of the most recently created breakpoint id.
  %p -- Prefix argument to the command (if any) as a number.
  %c -- Fully qualified class name derived from the expression
        surrounding point (jdb only).

  The `current' source file is the file of the current buffer (if
we're in a C file) or the source file current at the last break or
step (if we're in the GUD buffer).
  The `current' line is that of the current buffer (if we're in a
source file) or the source line number at the last break or step (if
we're in the GUD buffer).&quot;</span>
  `(<span class="enscript-keyword">progn</span>
     (defun ,func (arg)
       ,@(<span class="enscript-keyword">if</span> doc (list doc))
       (interactive <span class="enscript-string">&quot;p&quot;</span>)
       (<span class="enscript-keyword">if</span> (not gud-running)
	 ,(<span class="enscript-keyword">if</span> (stringp cmd)
	      `(gud-call ,cmd arg)
	    cmd)))
     ,(<span class="enscript-keyword">if</span> key `(local-set-key ,(concat <span class="enscript-string">&quot;\C-c&quot;</span> key) ',func))
     ,(<span class="enscript-keyword">if</span> key `(global-set-key (vconcat gud-key-prefix ,key) ',func))))

<span class="enscript-comment">;; Where gud-display-frame should put the debugging arrow; a cons of
</span><span class="enscript-comment">;; (filename . line-number).  This is set by the marker-filter, which scans
</span><span class="enscript-comment">;; the debugger's output for indications of the current program counter.
</span>(defvar gud-last-frame nil)

<span class="enscript-comment">;; Used by gud-refresh, which should cause gud-display-frame to redisplay
</span><span class="enscript-comment">;; the last frame, even if it's been called before and gud-last-frame has
</span><span class="enscript-comment">;; been set to nil.
</span>(defvar gud-last-last-frame nil)

<span class="enscript-comment">;; All debugger-specific information is collected here.
</span><span class="enscript-comment">;; Here's how it works, in case you ever need to add a debugger to the mode.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Each entry must define the following at startup:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;&lt;name&gt;
</span><span class="enscript-comment">;; comint-prompt-regexp
</span><span class="enscript-comment">;; gud-&lt;name&gt;-massage-args
</span><span class="enscript-comment">;; gud-&lt;name&gt;-marker-filter
</span><span class="enscript-comment">;; gud-&lt;name&gt;-find-file
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; The job of the massage-args method is to modify the given list of
</span><span class="enscript-comment">;; debugger arguments before running the debugger.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; The job of the marker-filter method is to detect file/line markers in
</span><span class="enscript-comment">;; strings and set the global gud-last-frame to indicate what display
</span><span class="enscript-comment">;; action (if any) should be triggered by the marker.  Note that only
</span><span class="enscript-comment">;; whatever the method *returns* is displayed in the buffer; thus, you
</span><span class="enscript-comment">;; can filter the debugger's output, interpreting some and passing on
</span><span class="enscript-comment">;; the rest.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; The job of the find-file method is to visit and return the buffer indicated
</span><span class="enscript-comment">;; by the car of gud-tag-frame.  This may be a file name, a tag name, or
</span><span class="enscript-comment">;; something else.
</span>
<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; speedbar support functions and variables.
</span>(<span class="enscript-keyword">eval-when-compile</span> (require 'speedbar))	<span class="enscript-comment">;For speedbar-with-attached-buffer.
</span>
(defvar gud-last-speedbar-stackframe nil
  <span class="enscript-string">&quot;Description of the currently displayed GUD stack.
The value t means that there is no stack, and we are in display-file mode.&quot;</span>)

(defvar gud-speedbar-key-map nil
  <span class="enscript-string">&quot;Keymap used when in the buffers display mode.&quot;</span>)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-speedbar-item-info</span> ()
  <span class="enscript-string">&quot;Display the data type of the watch expression element.&quot;</span>
  (<span class="enscript-keyword">let</span> ((var (nth (- (line-number-at-pos (point)) 2) gdb-var-list)))
    (<span class="enscript-keyword">if</span> (nth 6 var)
	(speedbar-message <span class="enscript-string">&quot;%s: %s&quot;</span> (nth 6 var) (nth 3 var))
      (speedbar-message <span class="enscript-string">&quot;%s&quot;</span> (nth 3 var)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-install-speedbar-variables</span> ()
  <span class="enscript-string">&quot;Install those variables used by speedbar to enhance gud/gdb.&quot;</span>
  (<span class="enscript-keyword">if</span> gud-speedbar-key-map
      nil
    (setq gud-speedbar-key-map (speedbar-make-specialized-keymap))

    (define-key gud-speedbar-key-map <span class="enscript-string">&quot;j&quot;</span> 'speedbar-edit-line)
    (define-key gud-speedbar-key-map <span class="enscript-string">&quot;e&quot;</span> 'speedbar-edit-line)
    (define-key gud-speedbar-key-map <span class="enscript-string">&quot;\C-m&quot;</span> 'speedbar-edit-line)
    (define-key gud-speedbar-key-map <span class="enscript-string">&quot; &quot;</span> 'speedbar-toggle-line-expansion)
    (define-key gud-speedbar-key-map <span class="enscript-string">&quot;D&quot;</span> 'gdb-var-delete)
    (define-key gud-speedbar-key-map <span class="enscript-string">&quot;p&quot;</span> 'gud-pp))

  (speedbar-add-expansion-list '(<span class="enscript-string">&quot;GUD&quot;</span> gud-speedbar-menu-items
				 gud-speedbar-key-map
				 gud-expansion-speedbar-buttons))

  (add-to-list
   'speedbar-mode-functions-list
   '(<span class="enscript-string">&quot;GUD&quot;</span> (speedbar-item-info . gud-speedbar-item-info)
     (speedbar-line-directory . ignore))))

(defvar gud-speedbar-menu-items
  '([<span class="enscript-string">&quot;Jump to stack frame&quot;</span> speedbar-edit-line
     <span class="enscript-reference">:visible</span> (not (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		    '(gdbmi gdba)))]
    [<span class="enscript-string">&quot;Edit value&quot;</span> speedbar-edit-line
     <span class="enscript-reference">:visible</span> (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		    '(gdbmi gdba))]
    [<span class="enscript-string">&quot;Delete expression&quot;</span> gdb-var-delete
     <span class="enscript-reference">:visible</span> (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		    '(gdbmi gdba))]
    [<span class="enscript-string">&quot;Auto raise frame&quot;</span> gdb-speedbar-auto-raise
     <span class="enscript-reference">:style</span> toggle <span class="enscript-reference">:selected</span> gdb-speedbar-auto-raise
     <span class="enscript-reference">:visible</span> (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		    '(gdbmi gdba))]
    (<span class="enscript-string">&quot;Output Format&quot;</span>
     <span class="enscript-reference">:visible</span> (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		    '(gdbmi gdba))
     [<span class="enscript-string">&quot;Binary&quot;</span> (gdb-var-set-format <span class="enscript-string">&quot;binary&quot;</span>) t]
     [<span class="enscript-string">&quot;Natural&quot;</span> (gdb-var-set-format  <span class="enscript-string">&quot;natural&quot;</span>) t]
     [<span class="enscript-string">&quot;Hexadecimal&quot;</span> (gdb-var-set-format <span class="enscript-string">&quot;hexadecimal&quot;</span>) t]))
  <span class="enscript-string">&quot;Additional menu items to add to the speedbar frame.&quot;</span>)

<span class="enscript-comment">;; Make sure our special speedbar mode is loaded
</span>(<span class="enscript-keyword">if</span> (featurep 'speedbar)
    (gud-install-speedbar-variables)
  (add-hook 'speedbar-load-hook 'gud-install-speedbar-variables))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-expansion-speedbar-buttons</span> (directory zero)
  <span class="enscript-string">&quot;Wrapper for call to `speedbar-add-expansion-list'.
DIRECTORY and ZERO are not used, but are required by the caller.&quot;</span>
  (gud-speedbar-buttons gud-comint-buffer))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-speedbar-buttons</span> (buffer)
  <span class="enscript-string">&quot;Create a speedbar display based on the current state of GUD.
If the GUD BUFFER is not running a supported debugger, then turn
off the specialized speedbar mode.  BUFFER is not used, but is
required by the caller.&quot;</span>
  (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> gud-comint-buffer
	     <span class="enscript-comment">;; gud-comint-buffer might be killed
</span>	     (buffer-name gud-comint-buffer))
    (<span class="enscript-keyword">let</span>* ((minor-mode (with-current-buffer buffer gud-minor-mode))
	  (window (get-buffer-window (current-buffer) 0))
	  (start (window-start window))
	  (p (window-point window)))
      (<span class="enscript-keyword">cond</span>
       ((memq minor-mode '(gdbmi gdba))
	(erase-buffer)
	(insert <span class="enscript-string">&quot;Watch Expressions:\n&quot;</span>)
	(<span class="enscript-keyword">if</span> gdb-speedbar-auto-raise
	    (raise-frame speedbar-frame))
	(<span class="enscript-keyword">let</span> ((var-list gdb-var-list) parent)
	  (<span class="enscript-keyword">while</span> var-list
	    (<span class="enscript-keyword">let</span>* (char (depth 0) (start 0) (var (car var-list))
			(varnum (car var)) (expr (nth 1 var))
			(type (<span class="enscript-keyword">if</span> (nth 3 var) (nth 3 var) <span class="enscript-string">&quot; &quot;</span>))
			(value (nth 4 var)) (status (nth 5 var)))
	      (put-text-property
	       0 (length expr) 'face font-lock-variable-name-face expr)
	      (put-text-property
	       0 (length type) 'face font-lock-type-face type)
	      (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\\.&quot;</span> varnum start)
		(setq depth (1+ depth)
		      start (1+ (match-beginning 0))))
	      (<span class="enscript-keyword">if</span> (eq depth 0) (setq parent nil))
	      (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> (equal (nth 2 var) <span class="enscript-string">&quot;0&quot;</span>)
		      (<span class="enscript-keyword">and</span> (equal (nth 2 var) <span class="enscript-string">&quot;1&quot;</span>)
			   (string-match <span class="enscript-string">&quot;char \\*$&quot;</span> type)))
		  (speedbar-make-tag-line
		   'bracket ?? nil nil
		   (concat expr <span class="enscript-string">&quot;\t&quot;</span> value)
		   (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> parent (eq status 'out-of-scope))
		       nil 'gdb-edit-value)
		   nil
		   (<span class="enscript-keyword">if</span> gdb-show-changed-values
		       (<span class="enscript-keyword">or</span> parent (case status
				    (changed 'font-lock-warning-face)
				    (out-of-scope 'shadow)
				    (t t)))
		     t)
		   depth)
		(<span class="enscript-keyword">if</span> (eq status 'out-of-scope) (setq parent 'shadow))
		(<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (nth 1 var-list)
			 (string-match (concat varnum <span class="enscript-string">&quot;\\.&quot;</span>)
				       (car (nth 1 var-list))))
		    (setq char ?-)
		  (setq char ?+))
		(<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;\\*$\\|\\*&amp;$&quot;</span> type)
		    (speedbar-make-tag-line
		     'bracket char
		     'gdb-speedbar-expand-node varnum
		     (concat expr <span class="enscript-string">&quot;\t&quot;</span> type <span class="enscript-string">&quot;\t&quot;</span> value)
		     (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> parent (eq status 'out-of-scope))
			 nil 'gdb-edit-value)
		     nil
		     (<span class="enscript-keyword">if</span> gdb-show-changed-values
			 (<span class="enscript-keyword">or</span> parent (case status
				      (changed 'font-lock-warning-face)
				      (out-of-scope 'shadow)
				      (t t)))
		       t)
		     depth)
		  (speedbar-make-tag-line
		   'bracket char
		   'gdb-speedbar-expand-node varnum
		   (concat expr <span class="enscript-string">&quot;\t&quot;</span> type)
		   nil nil
		   (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (<span class="enscript-keyword">or</span> parent status) gdb-show-changed-values)
		       'shadow t)
		   depth))))
	    (setq var-list (cdr var-list)))))
       (t (<span class="enscript-keyword">unless</span> (<span class="enscript-keyword">and</span> (<span class="enscript-keyword">save-excursion</span>
			 (goto-char (point-min))
			 (looking-at <span class="enscript-string">&quot;Current Stack:&quot;</span>))
		       (equal gud-last-last-frame gud-last-speedbar-stackframe))
	    (<span class="enscript-keyword">let</span> ((gud-frame-list
	    (<span class="enscript-keyword">cond</span> ((eq minor-mode 'gdb)
		   (gud-gdb-get-stackframe buffer))
		  <span class="enscript-comment">;; Add more debuggers here!
</span>		  (t (speedbar-remove-localized-speedbar-support buffer)
		     nil))))
	      (erase-buffer)
	      (<span class="enscript-keyword">if</span> (not gud-frame-list)
		  (insert <span class="enscript-string">&quot;No Stack frames\n&quot;</span>)
		(insert <span class="enscript-string">&quot;Current Stack:\n&quot;</span>))
	      (dolist (frame gud-frame-list)
		(insert (nth 1 frame) <span class="enscript-string">&quot;:\n&quot;</span>)
		(<span class="enscript-keyword">if</span> (= (length frame) 2)
		(<span class="enscript-keyword">progn</span>
		  (speedbar-insert-button (car frame)
					  'speedbar-directory-face
					  nil nil nil t))
		(speedbar-insert-button
		 (car frame)
		 'speedbar-file-face
		 'speedbar-highlight-face
		 (<span class="enscript-keyword">cond</span> ((memq minor-mode '(gdbmi gdba gdb))
			'gud-gdb-goto-stackframe)
		       (t (error <span class="enscript-string">&quot;Should never be here&quot;</span>)))
		 frame t))))
	    (setq gud-last-speedbar-stackframe gud-last-last-frame))))
      (set-window-start window start)
      (set-window-point window p))))


<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; gdb functions
</span>
<span class="enscript-comment">;; History of argument lists passed to gdb.
</span>(defvar gud-gdb-history nil)

(defcustom gud-gud-gdb-command-name <span class="enscript-string">&quot;gdb --fullname&quot;</span>
  <span class="enscript-string">&quot;Default command to run an executable under GDB in text command mode.
The option \&quot;--fullname\&quot; must be included in this value.&quot;</span>
   <span class="enscript-reference">:type</span> 'string
   <span class="enscript-reference">:group</span> 'gud)

(defvar gud-gdb-marker-regexp
  <span class="enscript-comment">;; This used to use path-separator instead of &quot;:&quot;;
</span>  <span class="enscript-comment">;; however, we found that on both Windows 32 and MSDOS
</span>  <span class="enscript-comment">;; a colon is correct here.
</span>  (concat <span class="enscript-string">&quot;\032\032\\(.:?[^&quot;</span> <span class="enscript-string">&quot;:&quot;</span> <span class="enscript-string">&quot;\n]*\\)&quot;</span> <span class="enscript-string">&quot;:&quot;</span>
	  <span class="enscript-string">&quot;\\([0-9]*\\)&quot;</span> <span class="enscript-string">&quot;:&quot;</span> <span class="enscript-string">&quot;.*\n&quot;</span>))

<span class="enscript-comment">;; There's no guarantee that Emacs will hand the filter the entire
</span><span class="enscript-comment">;; marker at once; it could be broken up across several strings.  We
</span><span class="enscript-comment">;; might even receive a big chunk with several markers in it.  If we
</span><span class="enscript-comment">;; receive a chunk of text which looks like it might contain the
</span><span class="enscript-comment">;; beginning of a marker, we save it here between calls to the
</span><span class="enscript-comment">;; filter.
</span>(defvar gud-marker-acc <span class="enscript-string">&quot;&quot;</span>)
(make-variable-buffer-local 'gud-marker-acc)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-marker-filter</span> (string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  (<span class="enscript-keyword">let</span> ((output <span class="enscript-string">&quot;&quot;</span>))

    <span class="enscript-comment">;; Process all the complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (string-match gud-gdb-marker-regexp gud-marker-acc)
      (setq

       <span class="enscript-comment">;; Extract the frame position from the marker.
</span>       gud-last-frame (cons (match-string 1 gud-marker-acc)
			    (string-to-number (match-string 2 gud-marker-acc)))

       <span class="enscript-comment">;; Append any text before the marker to the output we're going
</span>       <span class="enscript-comment">;; to return - we don't include the marker in this text.
</span>       output (concat output
		      (substring gud-marker-acc 0 (match-beginning 0)))

       <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    <span class="enscript-comment">;; Check for annotations and change gud-minor-mode to 'gdba if
</span>    <span class="enscript-comment">;; they are found.
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n\032\032\\(.*\\)\n&quot;</span> gud-marker-acc)
      (<span class="enscript-keyword">let</span> ((match (match-string 1 gud-marker-acc)))

	(setq
	 <span class="enscript-comment">;; Append any text before the marker to the output we're going
</span>	 <span class="enscript-comment">;; to return - we don't include the marker in this text.
</span>	 output (concat output
			(substring gud-marker-acc 0 (match-beginning 0)))

	 <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>
	 gud-marker-acc (substring gud-marker-acc (match-end 0)))))

    <span class="enscript-comment">;; Does the remaining text look like it might end with the
</span>    <span class="enscript-comment">;; beginning of another marker?  If it does, then keep it in
</span>    <span class="enscript-comment">;; gud-marker-acc until we receive the rest of it.  Since we
</span>    <span class="enscript-comment">;; know the full marker regexp above failed, it's pretty simple to
</span>    <span class="enscript-comment">;; test for marker starts.
</span>    (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;\n\\(\032.*\\)?\\'&quot;</span> gud-marker-acc)
	(<span class="enscript-keyword">progn</span>
	  <span class="enscript-comment">;; Everything before the potential marker start can be output.
</span>	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  <span class="enscript-comment">;; Everything after, we save, to combine with later input.
</span>	  (setq gud-marker-acc
		(substring gud-marker-acc (match-beginning 0))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc <span class="enscript-string">&quot;&quot;</span>))

    output))

(easy-mmode-defmap gud-minibuffer-local-map
  '((<span class="enscript-string">&quot;\C-i&quot;</span> . comint-dynamic-complete-filename))
  <span class="enscript-string">&quot;Keymap for minibuffer prompting of gud startup command.&quot;</span>
  <span class="enscript-reference">:inherit</span> minibuffer-local-map)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-query-cmdline</span> (minor-mode &amp;optional init)
  (<span class="enscript-keyword">let</span>* ((hist-sym (gud-symbol 'history nil minor-mode))
	 (cmd-name (gud-val 'command-name minor-mode)))
    (<span class="enscript-keyword">unless</span> (boundp hist-sym) (set hist-sym nil))
    (read-from-minibuffer
     (format <span class="enscript-string">&quot;Run %s (like this): &quot;</span> minor-mode)
     (<span class="enscript-keyword">or</span> (car-safe (symbol-value hist-sym))
	 (concat (<span class="enscript-keyword">or</span> cmd-name (symbol-name minor-mode))
		 <span class="enscript-string">&quot; &quot;</span>
		 (<span class="enscript-keyword">or</span> init
		     (<span class="enscript-keyword">let</span> ((file nil))
		       (dolist (f (directory-files default-directory) file)
			 (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (file-executable-p f)
				  (not (file-directory-p f))
				  (<span class="enscript-keyword">or</span> (not file)
				      (file-newer-than-file-p f file)))
			     (setq file f)))))))
     gud-minibuffer-local-map nil
     hist-sym)))

(defvar gdb-first-prompt t)

(defvar gud-filter-pending-text nil
  <span class="enscript-string">&quot;Non-nil means this is text that has been saved for later in `gud-filter'.&quot;</span>)

<span class="enscript-comment">;; The old gdb command (text command mode).  The new one is in gdb-ui.el.
</span><span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb</span> (command-line)
  <span class="enscript-string">&quot;Run gdb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working
directory and source-file directory for your debugger.&quot;</span>
  (interactive (list (gud-query-cmdline 'gud-gdb)))

  (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> gud-comint-buffer
	   (buffer-name gud-comint-buffer)
	   (get-buffer-process gud-comint-buffer)
	   (with-current-buffer gud-comint-buffer (eq gud-minor-mode 'gdba)))
	(gdb-restore-windows)
	(error
	 <span class="enscript-string">&quot;Multiple debugging requires restarting in text command mode&quot;</span>))

  (gud-common-init command-line nil 'gud-gdb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'gdb)

  (gud-def gud-break  <span class="enscript-string">&quot;break %f:%l&quot;</span>  <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-tbreak <span class="enscript-string">&quot;tbreak %f:%l&quot;</span> <span class="enscript-string">&quot;\C-t&quot;</span>
	   <span class="enscript-string">&quot;Set temporary breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;clear %f:%l&quot;</span> <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;step %p&quot;</span>     <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-stepi  <span class="enscript-string">&quot;stepi %p&quot;</span>    <span class="enscript-string">&quot;\C-i&quot;</span> <span class="enscript-string">&quot;Step one instruction with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;next %p&quot;</span>     <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-nexti  <span class="enscript-string">&quot;nexti %p&quot;</span> nil   <span class="enscript-string">&quot;Step one instruction (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;cont&quot;</span>     <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-finish <span class="enscript-string">&quot;finish&quot;</span>   <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>)
  (gud-def gud-jump
	   (<span class="enscript-keyword">progn</span> (gud-call <span class="enscript-string">&quot;tbreak %f:%l&quot;</span>) (gud-call <span class="enscript-string">&quot;jump %f:%l&quot;</span>))
	   <span class="enscript-string">&quot;\C-j&quot;</span> <span class="enscript-string">&quot;Set execution address to current line.&quot;</span>)

  (gud-def gud-up     <span class="enscript-string">&quot;up %p&quot;</span>     <span class="enscript-string">&quot;&lt;&quot;</span> <span class="enscript-string">&quot;Up N stack frames (numeric arg).&quot;</span>)
  (gud-def gud-down   <span class="enscript-string">&quot;down %p&quot;</span>   <span class="enscript-string">&quot;&gt;&quot;</span> <span class="enscript-string">&quot;Down N stack frames (numeric arg).&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;print %e&quot;</span>  <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate C expression at point.&quot;</span>)
  (gud-def gud-pstar  <span class="enscript-string">&quot;print* %e&quot;</span> nil
	   <span class="enscript-string">&quot;Evaluate C dereferenced pointer expression at point.&quot;</span>)

  <span class="enscript-comment">;; For debugging Emacs only.
</span>  (gud-def gud-pv <span class="enscript-string">&quot;pv1 %e&quot;</span>      <span class="enscript-string">&quot;\C-v&quot;</span> <span class="enscript-string">&quot;Print the value of the lisp variable.&quot;</span>)

  (gud-def gud-until  <span class="enscript-string">&quot;until %l&quot;</span> <span class="enscript-string">&quot;\C-u&quot;</span> <span class="enscript-string">&quot;Continue to current line.&quot;</span>)
  (gud-def gud-run    <span class="enscript-string">&quot;run&quot;</span>	 nil    <span class="enscript-string">&quot;Run the program.&quot;</span>)

  (local-set-key <span class="enscript-string">&quot;\C-i&quot;</span> 'gud-gdb-complete-command)
  (setq comint-prompt-regexp <span class="enscript-string">&quot;^(.*gdb[+]?) *&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (setq gdb-first-prompt t)
  (setq gud-running nil)
  (setq gdb-ready nil)
  (setq gud-filter-pending-text nil)
  (run-hooks 'gud-gdb-mode-hook))

<span class="enscript-comment">;; One of the nice features of GDB is its impressive support for
</span><span class="enscript-comment">;; context-sensitive command completion.  We preserve that feature
</span><span class="enscript-comment">;; in the GUD buffer by using a GDB command designed just for Emacs.
</span>
<span class="enscript-comment">;; The completion process filter indicates when it is finished.
</span>(defvar gud-gdb-fetch-lines-in-progress)

<span class="enscript-comment">;; Since output may arrive in fragments we accumulate partials strings here.
</span>(defvar gud-gdb-fetch-lines-string)

<span class="enscript-comment">;; We need to know how much of the completion to chop off.
</span>(defvar gud-gdb-fetch-lines-break)

<span class="enscript-comment">;; The completion list is constructed by the process filter.
</span>(defvar gud-gdb-fetched-lines)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-complete-command</span> (&amp;optional command a b)
  <span class="enscript-string">&quot;Perform completion on the GDB command preceding point.
This is implemented using the GDB `complete' command which isn't
available with older versions of GDB.&quot;</span>
  (interactive)
  (<span class="enscript-keyword">if</span> command
      <span class="enscript-comment">;; Used by gud-watch in mini-buffer.
</span>      (setq command (concat <span class="enscript-string">&quot;p &quot;</span> command))
    <span class="enscript-comment">;; Used in GUD buffer.
</span>    (<span class="enscript-keyword">let</span> ((end (point)))
      (setq command (buffer-substring (comint-line-beginning-position) end))))
  (<span class="enscript-keyword">let</span>* ((command-word
	  <span class="enscript-comment">;; Find the word break.  This match will always succeed.
</span>	  (<span class="enscript-keyword">and</span> (string-match <span class="enscript-string">&quot;\\(\\`\\| \\)\\([^ ]*\\)\\'&quot;</span> command)
	       (substring command (match-beginning 2))))
	 (complete-list
	  (gud-gdb-run-command-fetch-lines (concat <span class="enscript-string">&quot;complete &quot;</span> command)
					   (current-buffer)
					   <span class="enscript-comment">;; From string-match above.
</span>					   (match-beginning 2))))
    <span class="enscript-comment">;; Protect against old versions of GDB.
</span>    (<span class="enscript-keyword">and</span> complete-list
	 (string-match <span class="enscript-string">&quot;^Undefined command: \&quot;complete\&quot;&quot;</span> (car complete-list))
	 (error <span class="enscript-string">&quot;This version of GDB doesn't support the `complete' command&quot;</span>))
    <span class="enscript-comment">;; Sort the list like readline.
</span>    (setq complete-list (sort complete-list (function string-lessp)))
    <span class="enscript-comment">;; Remove duplicates.
</span>    (<span class="enscript-keyword">let</span> ((first complete-list)
	  (second (cdr complete-list)))
      (<span class="enscript-keyword">while</span> second
	(<span class="enscript-keyword">if</span> (string-equal (car first) (car second))
	    (setcdr first (setq second (cdr second)))
	  (setq first second
		second (cdr second)))))
    <span class="enscript-comment">;; Add a trailing single quote if there is a unique completion
</span>    <span class="enscript-comment">;; and it contains an odd number of unquoted single quotes.
</span>    (<span class="enscript-keyword">and</span> (= (length complete-list) 1)
	 (<span class="enscript-keyword">let</span> ((str (car complete-list))
	       (pos 0)
	       (count 0))
	   (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\\([^'\\]\\|\\\\'\\)*'&quot;</span> str pos)
	     (setq count (1+ count)
		   pos (match-end 0)))
	   (<span class="enscript-keyword">and</span> (= (mod count 2) 1)
		(setq complete-list (list (concat str <span class="enscript-string">&quot;'&quot;</span>))))))
    <span class="enscript-comment">;; Let comint handle the rest.
</span>    (comint-dynamic-simple-complete command-word complete-list)))

<span class="enscript-comment">;; The completion process filter is installed temporarily to slurp the
</span><span class="enscript-comment">;; output of GDB up to the next prompt and build the completion list.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-fetch-lines-filter</span> (string filter)
  <span class="enscript-string">&quot;Filter used to read the list of lines output by a command.
STRING is the output to filter.
It is passed through FILTER before we look at it.&quot;</span>
  (setq string (funcall filter string))
  (setq string (concat gud-gdb-fetch-lines-string string))
  (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> string)
    (push (substring string gud-gdb-fetch-lines-break (match-beginning 0))
	  gud-gdb-fetched-lines)
    (setq string (substring string (match-end 0))))
  (<span class="enscript-keyword">if</span> (string-match comint-prompt-regexp string)
      (<span class="enscript-keyword">progn</span>
	(setq gud-gdb-fetch-lines-in-progress nil)
	string)
    (<span class="enscript-keyword">progn</span>
      (setq gud-gdb-fetch-lines-string string)
      <span class="enscript-string">&quot;&quot;</span>)))

<span class="enscript-comment">;; gdb speedbar functions
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-goto-stackframe</span> (text token indent)
  <span class="enscript-string">&quot;Goto the stackframe described by TEXT, TOKEN, and INDENT.&quot;</span>
  (speedbar-with-attached-buffer
   (gud-basic-call (concat <span class="enscript-string">&quot;server frame &quot;</span> (nth 1 token)))
   (sit-for 1)))

(defvar gud-gdb-fetched-stack-frame nil
  <span class="enscript-string">&quot;Stack frames we are fetching from GDB.&quot;</span>)

<span class="enscript-comment">;(defun gud-gdb-get-scope-data (text token indent)
</span><span class="enscript-comment">;  ;; checkdoc-params: (indent)
</span><span class="enscript-comment">;  &quot;Fetch data associated with a stack frame, and expand/contract it.
</span><span class="enscript-comment">;Data to do this is retrieved from TEXT and TOKEN.&quot;
</span><span class="enscript-comment">;  (let ((args nil) (scope nil))
</span><span class="enscript-comment">;    (gud-gdb-run-command-fetch-lines &quot;info args&quot;)
</span><span class="enscript-comment">;
</span><span class="enscript-comment">;    (gud-gdb-run-command-fetch-lines &quot;info local&quot;)
</span><span class="enscript-comment">;
</span><span class="enscript-comment">;    ))
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-get-stackframe</span> (buffer)
  <span class="enscript-string">&quot;Extract the current stack frame out of the GUD GDB BUFFER.&quot;</span>
  (<span class="enscript-keyword">let</span> ((newlst nil)
	(fetched-stack-frame-list
	 (gud-gdb-run-command-fetch-lines <span class="enscript-string">&quot;server backtrace&quot;</span> buffer)))
    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (car fetched-stack-frame-list)
	     (string-match <span class="enscript-string">&quot;No stack&quot;</span> (car fetched-stack-frame-list)))
	<span class="enscript-comment">;; Go into some other mode???
</span>	nil
      (dolist (e fetched-stack-frame-list)
	(<span class="enscript-keyword">let</span> ((name nil) (num nil))
	  (<span class="enscript-keyword">if</span> (not (<span class="enscript-keyword">or</span>
		    (string-match <span class="enscript-string">&quot;^#\\([0-9]+\\) +[0-9a-fx]+ in \\([:0-9a-zA-Z_]+\\) (&quot;</span> e)
		    (string-match <span class="enscript-string">&quot;^#\\([0-9]+\\) +\\([:0-9a-zA-Z_]+\\) (&quot;</span> e)))
	      (<span class="enscript-keyword">if</span> (not (string-match
			<span class="enscript-string">&quot;at \\([-0-9a-zA-Z_.]+\\):\\([0-9]+\\)$&quot;</span> e))
		  nil
		(setcar newlst
			(list (nth 0 (car newlst))
			      (nth 1 (car newlst))
			      (match-string 1 e)
			      (match-string 2 e))))
	    (setq num (match-string 1 e)
		  name (match-string 2 e))
	    (setq newlst
		  (cons
		   (<span class="enscript-keyword">if</span> (string-match
			<span class="enscript-string">&quot;at \\([-0-9a-zA-Z_.]+\\):\\([0-9]+\\)$&quot;</span> e)
		       (list name num (match-string 1 e)
			     (match-string 2 e))
		     (list name num))
		   newlst)))))
      (nreverse newlst))))

<span class="enscript-comment">;(defun gud-gdb-selected-frame-info (buffer)
</span><span class="enscript-comment">;  &quot;Learn GDB information for the currently selected stack frame in BUFFER.&quot;
</span><span class="enscript-comment">;  )
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-gdb-run-command-fetch-lines</span> (command buffer &amp;optional skip)
  <span class="enscript-string">&quot;Run COMMAND, and return the list of lines it outputs.
BUFFER is the current buffer which may be the GUD buffer in which to run.
SKIP is the number of chars to skip on each line, it defaults to 0.&quot;</span>
  (with-current-buffer gud-comint-buffer
    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (eq gud-comint-buffer buffer)
	     (<span class="enscript-keyword">save-excursion</span>
	       (goto-char (point-max))
	       (forward-line 0)
	       (not (looking-at comint-prompt-regexp))))
	nil
      <span class="enscript-comment">;; Much of this copied from GDB complete, but I'm grabbing the stack
</span>      <span class="enscript-comment">;; frame instead.
</span>      (<span class="enscript-keyword">let</span> ((gud-gdb-fetch-lines-in-progress t)
	    (gud-gdb-fetched-lines nil)
	    (gud-gdb-fetch-lines-string nil)
	    (gud-gdb-fetch-lines-break (<span class="enscript-keyword">or</span> skip 0))
	    (gud-marker-filter
	     `(<span class="enscript-keyword">lambda</span> (string)
		(gud-gdb-fetch-lines-filter string ',gud-marker-filter))))
	<span class="enscript-comment">;; Issue the command to GDB.
</span>	(gud-basic-call command)
	<span class="enscript-comment">;; Slurp the output.
</span>	(<span class="enscript-keyword">while</span> gud-gdb-fetch-lines-in-progress
	  (accept-process-output (get-buffer-process gud-comint-buffer)))
	(nreverse gud-gdb-fetched-lines)))))


<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; lldb functions
</span>
<span class="enscript-comment">;; History of argument lists passed to lldb.
</span>(defvar gud-lldb-history nil)

<span class="enscript-comment">;; Keeps track of breakpoint created.  In the following case, the id is &quot;1&quot;.
</span><span class="enscript-comment">;; It is used to implement temporary breakpoint.
</span><span class="enscript-comment">;; (lldb) b main.c:39
</span><span class="enscript-comment">;; breakpoint set --file 'main.c' --line 39
</span><span class="enscript-comment">;; Breakpoint created: 1: file ='main.c', line = 39, locations = 1
</span>(defvar gud-breakpoint-id nil)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">lldb-extract-breakpoint-id</span> (string)
  <span class="enscript-comment">;; Search for &quot;Breakpoint created: \\([^:\n]*\\):&quot; pattern.
</span>  <span class="enscript-comment">;(message &quot;gud-marker-acc string is: |%s|&quot; string)
</span>  (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;Breakpoint created: \\([^:\n]*\\):&quot;</span> string)
      (<span class="enscript-keyword">progn</span>
        (setq gud-breakpoint-id (match-string 1 string))
        (message <span class="enscript-string">&quot;breakpoint id: %s&quot;</span> gud-breakpoint-id)))
)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-lldb-marker-filter</span> (string)
  (setq gud-marker-acc
	(<span class="enscript-keyword">if</span> gud-marker-acc (concat gud-marker-acc string) string))
  (lldb-extract-breakpoint-id gud-marker-acc)
  (<span class="enscript-keyword">let</span> (start)
    <span class="enscript-comment">;; Process all complete markers in this chunk
</span>    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">or</span>
            <span class="enscript-comment">;; (lldb) r
</span>            <span class="enscript-comment">;; Process 15408 launched: '/Volumes/data/lldb/svn/trunk/test/conditional_break/a.out' (x86_64)
</span>            <span class="enscript-comment">;; (lldb) Process 15408 stopped
</span>            <span class="enscript-comment">;; * thread #1: tid = 0x2e03, 0x0000000100000de8 a.out`c + 7 at main.c:39, stop reason = breakpoint 1.1, queue = com.apple.main-thread
</span>            (string-match <span class="enscript-string">&quot; at \\([^:\n]*\\):\\([0-9]*\\), stop reason = .*\n&quot;</span>
                          gud-marker-acc start)
            <span class="enscript-comment">;; (lldb) frame select -r 1
</span>            <span class="enscript-comment">;; frame #1: 0x0000000100000e09 a.out`main + 25 at main.c:44
</span>            (string-match <span class="enscript-string">&quot;^frame.* at \\([^:\n]*\\):\\([0-9]*\\)\n&quot;</span>
                           gud-marker-acc start))
      <span class="enscript-comment">;(message &quot;gud-marker-acc matches our pattern....&quot;)
</span>      (setq gud-last-frame
            (cons (match-string 1 gud-marker-acc)
                  (string-to-number (match-string 2 gud-marker-acc)))
            start (match-end 0)))

    <span class="enscript-comment">;; Search for the last incomplete line in this chunk
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> gud-marker-acc start)
      (setq start (match-end 0)))

    <span class="enscript-comment">;; If we have an incomplete line, store it in gud-marker-acc.
</span>    (setq gud-marker-acc (substring gud-marker-acc (<span class="enscript-keyword">or</span> start 0))))
  string)

<span class="enscript-comment">;; Keeps track of whether the Python lldb_oneshot_break function definition has
</span><span class="enscript-comment">;; been exec'ed.
</span>(defvar lldb-oneshot-break-defined nil)

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">lldb</span> (command-line)
  <span class="enscript-string">&quot;Run lldb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.&quot;</span>
  (interactive (list (gud-query-cmdline 'lldb)))

  (gud-common-init command-line nil 'gud-lldb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'lldb)
  (setq lldb-oneshot-break-defined nil)

  <span class="enscript-comment">;; Make lldb dump fullpath instead of basename for a file.
</span>  <span class="enscript-comment">;; See also gud-lldb-marker-filter where gud-last-frame is grokked from lldb output.
</span>  (<span class="enscript-keyword">progn</span>
    (gud-call <span class="enscript-string">&quot;settings set frame-format frame #${frame.index}: ${frame.pc}{ ${module.file.basename}{`${function.name}${function.pc-offset}}}{ at ${line.file.fullpath}:${line.number}}\\n&quot;</span>)
    (sit-for 1)
    (gud-call <span class="enscript-string">&quot;settings set thread-format thread #${thread.index}: tid = ${thread.id}{, ${frame.pc}}{ ${module.file.basename}{`${function.name}${function.pc-offset}}}{ at ${line.file.fullpath}:${line.number}}{, stop reason = ${thread.stop-reason}}\\n&quot;</span>)
    (sit-for 1))

  (gud-def gud-listb  <span class="enscript-string">&quot;breakpoint list&quot;</span>
                      <span class="enscript-string">&quot;l&quot;</span>    <span class="enscript-string">&quot;List all breakpoints.&quot;</span>)
  (gud-def gud-bt     <span class="enscript-string">&quot;thread backtrace&quot;</span>
                      <span class="enscript-string">&quot;b&quot;</span>    <span class="enscript-string">&quot;Show stack for the current thread.&quot;</span>)
  (gud-def gud-bt-all <span class="enscript-string">&quot;thread backtrace all&quot;</span>
                      <span class="enscript-string">&quot;B&quot;</span>    <span class="enscript-string">&quot;Show stacks for all the threads.&quot;</span>)

  (gud-def gud-break  <span class="enscript-string">&quot;breakpoint set -f %f -l %l&quot;</span>
                      <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-tbreak
	   (<span class="enscript-keyword">progn</span> (gud-call <span class="enscript-string">&quot;breakpoint set -f %f -l %l&quot;</span>)
                  (sit-for 1)
                  (<span class="enscript-keyword">if</span> (not lldb-oneshot-break-defined)
                      (<span class="enscript-keyword">progn</span>
                        <span class="enscript-comment">;; The &quot;\\n&quot;'s are required to escape the newline chars
</span>                        <span class="enscript-comment">;; passed to the lldb process.
</span>                        (gud-call (concat <span class="enscript-string">&quot;script exec \&quot;def lldb_oneshot_break(frame, bp_loc):\\n&quot;</span>
                                                        <span class="enscript-string">&quot;    target=frame.GetThread().GetProcess().GetTarget()\\n&quot;</span>
                                                        <span class="enscript-string">&quot;    bp=bp_loc.GetBreakpoint()\\n&quot;</span>
                                                        <span class="enscript-string">&quot;    print 'Deleting oneshot breakpoint:', bp\\n&quot;</span>
                                                        <span class="enscript-string">&quot;    target.BreakpointDelete(bp.GetID())\&quot;&quot;</span>))
                        (sit-for 1)
                        <span class="enscript-comment">;; Set the flag since Python knows about the function def now.
</span>                        (setq lldb-oneshot-break-defined t)))
                  (gud-call <span class="enscript-string">&quot;breakpoint command add -p %b -o 'lldb_oneshot_break(frame, bp_loc)'&quot;</span>))
	              <span class="enscript-string">&quot;\C-t&quot;</span> <span class="enscript-string">&quot;Set temporary breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;breakpoint clear -f %f -l %l&quot;</span>
                      <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;thread step-in&quot;</span>
                      <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-stepi  <span class="enscript-string">&quot;thread step-inst&quot;</span>
                      <span class="enscript-string">&quot;\C-i&quot;</span> <span class="enscript-string">&quot;Step one instruction with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;thread step-over&quot;</span>
                      <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-nexti  <span class="enscript-string">&quot;thread step-inst-over&quot;</span>
                      nil    <span class="enscript-string">&quot;Step one instruction (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;process continue&quot;</span>
                      <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-finish <span class="enscript-string">&quot;thread step-out&quot;</span>
                      <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>)
  (gud-def gud-up
           (<span class="enscript-keyword">progn</span> (gud-call <span class="enscript-string">&quot;frame select -r 1&quot;</span>)
                  (sit-for 1))
                      <span class="enscript-string">&quot;&lt;&quot;</span>    <span class="enscript-string">&quot;Up 1 stack frame.&quot;</span>)
  (gud-def gud-down
           (<span class="enscript-keyword">progn</span> (gud-call <span class="enscript-string">&quot;frame select -r -1&quot;</span>)
                  (sit-for 1))
                      <span class="enscript-string">&quot;&gt;&quot;</span>    <span class="enscript-string">&quot;Down 1 stack frame.&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;expression -- %e&quot;</span>
                      <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate C expression at point.&quot;</span>)
  (gud-def gud-pstar  <span class="enscript-string">&quot;expression -- *%e&quot;</span>
                      nil    <span class="enscript-string">&quot;Evaluate C dereferenced pointer expression at point.&quot;</span>)
  (gud-def gud-run    <span class="enscript-string">&quot;run&quot;</span>
                      <span class="enscript-string">&quot;r&quot;</span>    <span class="enscript-string">&quot;Run the program.&quot;</span>)
  (gud-def gud-stop-subjob    <span class="enscript-string">&quot;process kill&quot;</span>
                      <span class="enscript-string">&quot;s&quot;</span>    <span class="enscript-string">&quot;Stop the program.&quot;</span>)

  (setq comint-prompt-regexp  <span class="enscript-string">&quot;\\(^\\|\n\\)\\*&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'lldb-mode-hook)
  )


<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; sdb functions
</span>
<span class="enscript-comment">;; History of argument lists passed to sdb.
</span>(defvar gud-sdb-history nil)

(defvar gud-sdb-needs-tags (not (file-exists-p <span class="enscript-string">&quot;/var&quot;</span>))
  <span class="enscript-string">&quot;If nil, we're on a System V Release 4 and don't need the tags hack.&quot;</span>)

(defvar gud-sdb-lastfile nil)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-sdb-marker-filter</span> (string)
  (setq gud-marker-acc
	(<span class="enscript-keyword">if</span> gud-marker-acc (concat gud-marker-acc string) string))
  (<span class="enscript-keyword">let</span> (start)
    <span class="enscript-comment">;; Process all complete markers in this chunk
</span>    (<span class="enscript-keyword">while</span>
	(<span class="enscript-keyword">cond</span>
	 <span class="enscript-comment">;; System V Release 3.2 uses this format
</span>	 ((string-match <span class="enscript-string">&quot;\\(^\\|\n\\)\\*?\\(0x\\w* in \\)?\\([^:\n]*\\):\\([0-9]*\\):.*\n&quot;</span>
			gud-marker-acc start)
	  (setq gud-last-frame
		(cons (match-string 3 gud-marker-acc)
		      (string-to-number (match-string 4 gud-marker-acc)))))
	 <span class="enscript-comment">;; System V Release 4.0 quite often clumps two lines together
</span>	 ((string-match <span class="enscript-string">&quot;^\\(BREAKPOINT\\|STEPPED\\) process [0-9]+ function [^ ]+ in \\(.+\\)\n\\([0-9]+\\):&quot;</span>
			gud-marker-acc start)
	  (setq gud-sdb-lastfile (match-string 2 gud-marker-acc))
	  (setq gud-last-frame
		(cons gud-sdb-lastfile
		      (string-to-number (match-string 3 gud-marker-acc)))))
	 <span class="enscript-comment">;; System V Release 4.0
</span>	 ((string-match <span class="enscript-string">&quot;^\\(BREAKPOINT\\|STEPPED\\) process [0-9]+ function [^ ]+ in \\(.+\\)\n&quot;</span>
			gud-marker-acc start)
	  (setq gud-sdb-lastfile (match-string 2 gud-marker-acc)))
	 ((<span class="enscript-keyword">and</span> gud-sdb-lastfile (string-match <span class="enscript-string">&quot;^\\([0-9]+\\):&quot;</span>
					      gud-marker-acc start))
	       (setq gud-last-frame
		     (cons gud-sdb-lastfile
			   (string-to-number (match-string 1 gud-marker-acc)))))
	 (t
	  (setq gud-sdb-lastfile nil)))
      (setq start (match-end 0)))

    <span class="enscript-comment">;; Search for the last incomplete line in this chunk
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> gud-marker-acc start)
      (setq start (match-end 0)))

    <span class="enscript-comment">;; If we have an incomplete line, store it in gud-marker-acc.
</span>    (setq gud-marker-acc (substring gud-marker-acc (<span class="enscript-keyword">or</span> start 0))))
  string)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-sdb-find-file</span> (f)
  (<span class="enscript-keyword">if</span> gud-sdb-needs-tags (find-tag-noselect f) (find-file-noselect f)))

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">sdb</span> (command-line)
  <span class="enscript-string">&quot;Run sdb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.&quot;</span>
  (interactive (list (gud-query-cmdline 'sdb)))

  (<span class="enscript-keyword">if</span> gud-sdb-needs-tags (require 'etags))
  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> gud-sdb-needs-tags
	   (not (<span class="enscript-keyword">and</span> (boundp 'tags-file-name)
		     (stringp tags-file-name)
		     (file-exists-p tags-file-name))))
      (error <span class="enscript-string">&quot;The sdb support requires a valid tags table to work&quot;</span>))

  (gud-common-init command-line nil 'gud-sdb-marker-filter 'gud-sdb-find-file)
  (set (make-local-variable 'gud-minor-mode) 'sdb)

  (gud-def gud-break  <span class="enscript-string">&quot;%l b&quot;</span> <span class="enscript-string">&quot;\C-b&quot;</span>   <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-tbreak <span class="enscript-string">&quot;%l c&quot;</span> <span class="enscript-string">&quot;\C-t&quot;</span>   <span class="enscript-string">&quot;Set temporary breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;%l d&quot;</span> <span class="enscript-string">&quot;\C-d&quot;</span>   <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;s %p&quot;</span> <span class="enscript-string">&quot;\C-s&quot;</span>   <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-stepi  <span class="enscript-string">&quot;i %p&quot;</span> <span class="enscript-string">&quot;\C-i&quot;</span>   <span class="enscript-string">&quot;Step one instruction with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;S %p&quot;</span> <span class="enscript-string">&quot;\C-n&quot;</span>   <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;c&quot;</span>    <span class="enscript-string">&quot;\C-r&quot;</span>   <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;%e/&quot;</span>  <span class="enscript-string">&quot;\C-p&quot;</span>   <span class="enscript-string">&quot;Evaluate C expression at point.&quot;</span>)

  (setq comint-prompt-regexp  <span class="enscript-string">&quot;\\(^\\|\n\\)\\*&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'sdb-mode-hook)
  )

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; dbx functions
</span>
<span class="enscript-comment">;; History of argument lists passed to dbx.
</span>(defvar gud-dbx-history nil)

(defcustom gud-dbx-directories nil
  <span class="enscript-string">&quot;*A list of directories that dbx should search for source code.
If nil, only source files in the program directory
will be known to dbx.

The file names should be absolute, or relative to the directory
containing the executable being debugged.&quot;</span>
  <span class="enscript-reference">:type</span> '(choice (const <span class="enscript-reference">:tag</span> <span class="enscript-string">&quot;Current Directory&quot;</span> nil)
		 (repeat <span class="enscript-reference">:value</span> (<span class="enscript-string">&quot;&quot;</span>)
			 directory))
  <span class="enscript-reference">:group</span> 'gud)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-dbx-massage-args</span> (file args)
  (nconc (<span class="enscript-keyword">let</span> ((directories gud-dbx-directories)
	       (result nil))
	   (<span class="enscript-keyword">while</span> directories
	     (setq result (cons (car directories) (cons <span class="enscript-string">&quot;-I&quot;</span> result)))
	     (setq directories (cdr directories)))
	   (nreverse result))
	 args))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-dbx-marker-filter</span> (string)
  (setq gud-marker-acc (<span class="enscript-keyword">if</span> gud-marker-acc (concat gud-marker-acc string) string))

  (<span class="enscript-keyword">let</span> (start)
    <span class="enscript-comment">;; Process all complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">or</span> (string-match
		<span class="enscript-string">&quot;stopped in .* at line \\([0-9]*\\) in file \&quot;\\([^\&quot;]*\\)\&quot;&quot;</span>
		gud-marker-acc start)
	       (string-match
		<span class="enscript-string">&quot;signal .* in .* at line \\([0-9]*\\) in file \&quot;\\([^\&quot;]*\\)\&quot;&quot;</span>
		gud-marker-acc start))
      (setq gud-last-frame
	    (cons (match-string 2 gud-marker-acc)
		  (string-to-number (match-string 1 gud-marker-acc)))
	    start (match-end 0)))

    <span class="enscript-comment">;; Search for the last incomplete line in this chunk
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> gud-marker-acc start)
      (setq start (match-end 0)))

    <span class="enscript-comment">;; If the incomplete line APPEARS to begin with another marker, keep it
</span>    <span class="enscript-comment">;; in the accumulator.  Otherwise, clear the accumulator to avoid an
</span>    <span class="enscript-comment">;; unnecessary concat during the next call.
</span>    (setq gud-marker-acc
	  (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;\\(stopped\\|signal\\)&quot;</span> gud-marker-acc start)
	      (substring gud-marker-acc (match-beginning 0))
	    nil)))
  string)

<span class="enscript-comment">;; Functions for Mips-style dbx.  Given the option `-emacs', documented in
</span><span class="enscript-comment">;; OSF1, not necessarily elsewhere, it produces markers similar to gdb's.
</span>(defvar gud-mips-p
  (<span class="enscript-keyword">or</span> (string-match <span class="enscript-string">&quot;^mips-[^-]*-ultrix&quot;</span> system-configuration)
      <span class="enscript-comment">;; We haven't tested gud on this system:
</span>      (string-match <span class="enscript-string">&quot;^mips-[^-]*-riscos&quot;</span> system-configuration)
      <span class="enscript-comment">;; It's documented on OSF/1.3
</span>      (string-match <span class="enscript-string">&quot;^mips-[^-]*-osf1&quot;</span> system-configuration)
      (string-match <span class="enscript-string">&quot;^alpha[^-]*-[^-]*-osf&quot;</span> system-configuration))
  <span class="enscript-string">&quot;Non-nil to assume the MIPS/OSF dbx conventions (argument `-emacs').&quot;</span>)

(defvar gud-dbx-command-name
  (concat <span class="enscript-string">&quot;dbx&quot;</span> (<span class="enscript-keyword">if</span> gud-mips-p <span class="enscript-string">&quot; -emacs&quot;</span>)))

<span class="enscript-comment">;; This is just like the gdb one except for the regexps since we need to cope
</span><span class="enscript-comment">;; with an optional breakpoint number in [] before the ^Z^Z
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-mipsdbx-marker-filter</span> (string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  (<span class="enscript-keyword">let</span> ((output <span class="enscript-string">&quot;&quot;</span>))

    <span class="enscript-comment">;; Process all the complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (string-match
	    <span class="enscript-comment">;; This is like th gdb marker but with an optional
</span>	    <span class="enscript-comment">;; leading break point number like `[1] '
</span>	    <span class="enscript-string">&quot;[][ 0-9]*\032\032\\([^:\n]*\\):\\([0-9]*\\):.*\n&quot;</span>
	    gud-marker-acc)
      (setq

       <span class="enscript-comment">;; Extract the frame position from the marker.
</span>       gud-last-frame
       (cons (match-string 1 gud-marker-acc)
	     (string-to-number (match-string 2 gud-marker-acc)))

       <span class="enscript-comment">;; Append any text before the marker to the output we're going
</span>       <span class="enscript-comment">;; to return - we don't include the marker in this text.
</span>       output (concat output
		      (substring gud-marker-acc 0 (match-beginning 0)))

       <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    <span class="enscript-comment">;; Does the remaining text look like it might end with the
</span>    <span class="enscript-comment">;; beginning of another marker?  If it does, then keep it in
</span>    <span class="enscript-comment">;; gud-marker-acc until we receive the rest of it.  Since we
</span>    <span class="enscript-comment">;; know the full marker regexp above failed, it's pretty simple to
</span>    <span class="enscript-comment">;; test for marker starts.
</span>    (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;[][ 0-9]*\032.*\\'&quot;</span> gud-marker-acc)
	(<span class="enscript-keyword">progn</span>
	  <span class="enscript-comment">;; Everything before the potential marker start can be output.
</span>	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  <span class="enscript-comment">;; Everything after, we save, to combine with later input.
</span>	  (setq gud-marker-acc
		(substring gud-marker-acc (match-beginning 0))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc <span class="enscript-string">&quot;&quot;</span>))

    output))

<span class="enscript-comment">;; The dbx in IRIX is a pain.  It doesn't print the file name when
</span><span class="enscript-comment">;; stopping at a breakpoint (but you do get it from the `up' and
</span><span class="enscript-comment">;; `down' commands...).  The only way to extract the information seems
</span><span class="enscript-comment">;; to be with a `file' command, although the current line number is
</span><span class="enscript-comment">;; available in $curline.  Thus we have to look for output which
</span><span class="enscript-comment">;; appears to indicate a breakpoint.  Then we prod the dbx sub-process
</span><span class="enscript-comment">;; to output the information we want with a combination of the
</span><span class="enscript-comment">;; `printf' and `file' commands as a pseudo marker which we can
</span><span class="enscript-comment">;; recognise next time through the marker-filter.  This would be like
</span><span class="enscript-comment">;; the gdb marker but you can't get the file name without a newline...
</span><span class="enscript-comment">;; Note that gud-remove won't work since Irix dbx expects a breakpoint
</span><span class="enscript-comment">;; number rather than a line number etc.  Maybe this could be made to
</span><span class="enscript-comment">;; work by listing all the breakpoints and picking the one(s) with the
</span><span class="enscript-comment">;; correct line number, but life's too short.
</span><span class="enscript-comment">;;   <a href="mailto:d.love@dl.ac.uk">d.love@dl.ac.uk</a> (Dave Love) can be blamed for this
</span>
(defvar gud-irix-p
  (<span class="enscript-keyword">and</span> (string-match <span class="enscript-string">&quot;^mips-[^-]*-irix&quot;</span> system-configuration)
       (not (string-match <span class="enscript-string">&quot;irix[6-9]\\.[1-9]&quot;</span> system-configuration)))
  <span class="enscript-string">&quot;Non-nil to assume the interface appropriate for IRIX dbx.
This works in IRIX 4, 5 and 6, but `gud-dbx-use-stopformat-p' provides
a better solution in 6.1 upwards.&quot;</span>)
(defvar gud-dbx-use-stopformat-p
  (string-match <span class="enscript-string">&quot;irix[6-9]\\.[1-9]&quot;</span> system-configuration)
  <span class="enscript-string">&quot;Non-nil to use the dbx feature present at least from Irix 6.1
whereby $stopformat=1 produces an output format compatible with
`gud-dbx-marker-filter'.&quot;</span>)
<span class="enscript-comment">;; [Irix dbx seems to be a moving target.  The dbx output changed
</span><span class="enscript-comment">;; subtly sometime between OS v4.0.5 and v5.2 so that, for instance,
</span><span class="enscript-comment">;; the output from `up' is no longer spotted by gud (and it's probably
</span><span class="enscript-comment">;; not distinctive enough to try to match it -- use C-&lt;, C-&gt;
</span><span class="enscript-comment">;; exclusively) .  For 5.3 and 6.0, the $curline variable changed to
</span><span class="enscript-comment">;; `long long'(why?!), so the printf stuff needed changing.  The line
</span><span class="enscript-comment">;; number was cast to `long' as a compromise between the new `long
</span><span class="enscript-comment">;; long' and the original `int'.  This is reported not to work in 6.2,
</span><span class="enscript-comment">;; so it's changed back to int -- don't make your sources too long.
</span><span class="enscript-comment">;; From Irix6.1 (but not 6.0?) dbx supports an undocumented feature
</span><span class="enscript-comment">;; whereby `set $stopformat=1' reportedly produces output compatible
</span><span class="enscript-comment">;; with `gud-dbx-marker-filter', which we prefer.
</span>
<span class="enscript-comment">;; The process filter is also somewhat
</span><span class="enscript-comment">;; unreliable, sometimes not spotting the markers; I don't know
</span><span class="enscript-comment">;; whether there's anything that can be done about that.  It would be
</span><span class="enscript-comment">;; much better if SGI could be persuaded to (re?)instate the MIPS
</span><span class="enscript-comment">;; -emacs flag for gdb-like output (which ought to be possible as most
</span><span class="enscript-comment">;; of the communication I've had over it has been from sgi.com).]
</span>
<span class="enscript-comment">;; this filter is influenced by the xdb one rather than the gdb one
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-irixdbx-marker-filter</span> (string)
  (<span class="enscript-keyword">let</span> (result (case-fold-search nil))
    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> (string-match comint-prompt-regexp string)
	    (string-match <span class="enscript-string">&quot;.*\012&quot;</span> string))
	(setq result (concat gud-marker-acc string)
	      gud-marker-acc <span class="enscript-string">&quot;&quot;</span>)
      (setq gud-marker-acc (concat gud-marker-acc string)))
    (<span class="enscript-keyword">if</span> result
	(<span class="enscript-keyword">cond</span>
	 <span class="enscript-comment">;; look for breakpoint or signal indication e.g.:
</span>	 <span class="enscript-comment">;; [2] Process  1267 (pplot) stopped at [params:338 ,0x400ec0]
</span>	 <span class="enscript-comment">;; Process  1281 (pplot) stopped at [params:339 ,0x400ec8]
</span>	 <span class="enscript-comment">;; Process  1270 (pplot) Floating point exception [._read._read:16 ,0x452188]
</span>	 ((string-match
	   <span class="enscript-string">&quot;^\\(\\[[0-9]+] \\)?Process +[0-9]+ ([^)]*) [^[]+\\[[^]\n]*]\n&quot;</span>
	   result)
	  <span class="enscript-comment">;; prod dbx into printing out the line number and file
</span>	  <span class="enscript-comment">;; name in a form we can grok as below
</span>	  (process-send-string (get-buffer-process gud-comint-buffer)
			       <span class="enscript-string">&quot;printf \&quot;\032\032%1d:\&quot;,(int)$curline;file\n&quot;</span>))
	 <span class="enscript-comment">;; look for result of, say, &quot;up&quot; e.g.:
</span>	 <span class="enscript-comment">;; .pplot.pplot(0x800) [&quot;src/pplot.f&quot;:261, 0x400c7c]
</span>	 <span class="enscript-comment">;; (this will also catch one of the lines printed by &quot;where&quot;)
</span>	 ((string-match
	   <span class="enscript-string">&quot;^[^ ][^[]*\\[\&quot;\\([^\&quot;]+\\)\&quot;:\\([0-9]+\\), [^]]+]\n&quot;</span>
	   result)
	  (<span class="enscript-keyword">let</span> ((file (match-string 1 result)))
	    (<span class="enscript-keyword">if</span> (file-exists-p file)
		(setq gud-last-frame
		      (cons (match-string 1 result)
			    (string-to-number (match-string 2 result))))))
	  result)
	 ((string-match			<span class="enscript-comment">; kluged-up marker as above
</span>	   <span class="enscript-string">&quot;\032\032\\([0-9]*\\):\\(.*\\)\n&quot;</span> result)
	  (<span class="enscript-keyword">let</span> ((file (gud-file-name (match-string 2 result))))
	    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> file (file-exists-p file))
		(setq gud-last-frame
		      (cons file
			    (string-to-number (match-string 1 result))))))
	  (setq result (substring result 0 (match-beginning 0))))))
    (<span class="enscript-keyword">or</span> result <span class="enscript-string">&quot;&quot;</span>)))

(defvar gud-dgux-p (string-match <span class="enscript-string">&quot;-dgux&quot;</span> system-configuration)
  <span class="enscript-string">&quot;Non-nil means to assume the interface approriate for DG/UX dbx.
This was tested using R4.11.&quot;</span>)

<span class="enscript-comment">;; There are a couple of differences between DG's dbx output and normal
</span><span class="enscript-comment">;; dbx output which make it nontrivial to integrate this into the
</span><span class="enscript-comment">;; standard dbx-marker-filter (mainly, there are a different number of
</span><span class="enscript-comment">;; backreferences).  The markers look like:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;     (0) Stopped at line 10, routine main(argc=1, argv=0xeffff0e0), file t.c
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; from breakpoints (the `(0)' there isn't constant, it's the breakpoint
</span><span class="enscript-comment">;; number), and
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;     Stopped at line 13, routine main(argc=1, argv=0xeffff0e0), file t.c
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; from signals and
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;     Frame 21, line 974, routine command_loop(), file keyboard.c
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; from up/down/where.
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-dguxdbx-marker-filter</span> (string)
  (setq gud-marker-acc (<span class="enscript-keyword">if</span> gud-marker-acc
			   (concat gud-marker-acc string)
			 string))
  (<span class="enscript-keyword">let</span> ((re (concat <span class="enscript-string">&quot;^\\(\\(([0-9]+) \\)?Stopped at\\|Frame [0-9]+,\\)&quot;</span>
		    <span class="enscript-string">&quot; line \\([0-9]+\\), routine .*, file \\([^ \t\n]+\\)&quot;</span>))
	start)
    <span class="enscript-comment">;; Process all complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (string-match re gud-marker-acc start)
      (setq gud-last-frame
	    (cons (match-string 4 gud-marker-acc)
		  (string-to-number (match-string 3 gud-marker-acc)))
	    start (match-end 0)))

    <span class="enscript-comment">;; Search for the last incomplete line in this chunk
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> gud-marker-acc start)
      (setq start (match-end 0)))

    <span class="enscript-comment">;; If the incomplete line APPEARS to begin with another marker, keep it
</span>    <span class="enscript-comment">;; in the accumulator.  Otherwise, clear the accumulator to avoid an
</span>    <span class="enscript-comment">;; unnecessary concat during the next call.
</span>    (setq gud-marker-acc
	  (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;Stopped\\|Frame&quot;</span> gud-marker-acc start)
	      (substring gud-marker-acc (match-beginning 0))
	    nil)))
  string)

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">dbx</span> (command-line)
  <span class="enscript-string">&quot;Run dbx on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.&quot;</span>
  (interactive (list (gud-query-cmdline 'dbx)))

  (<span class="enscript-keyword">cond</span>
   (gud-mips-p
    (gud-common-init command-line nil 'gud-mipsdbx-marker-filter))
   (gud-irix-p
    (gud-common-init command-line 'gud-dbx-massage-args
		     'gud-irixdbx-marker-filter))
   (gud-dgux-p
    (gud-common-init command-line 'gud-dbx-massage-args
		     'gud-dguxdbx-marker-filter))
   (t
    (gud-common-init command-line 'gud-dbx-massage-args
		     'gud-dbx-marker-filter)))

  (set (make-local-variable 'gud-minor-mode) 'dbx)

  (<span class="enscript-keyword">cond</span>
   (gud-mips-p
    (gud-def gud-up	<span class="enscript-string">&quot;up %p&quot;</span>	  <span class="enscript-string">&quot;&lt;&quot;</span> <span class="enscript-string">&quot;Up (numeric arg) stack frames.&quot;</span>)
    (gud-def gud-down	<span class="enscript-string">&quot;down %p&quot;</span> <span class="enscript-string">&quot;&gt;&quot;</span> <span class="enscript-string">&quot;Down (numeric arg) stack frames.&quot;</span>)
    (gud-def gud-break  <span class="enscript-string">&quot;stop at \&quot;%f\&quot;:%l&quot;</span>
				  <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
    (gud-def gud-finish <span class="enscript-string">&quot;return&quot;</span>  <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>))
   (gud-irix-p
    (gud-def gud-break  <span class="enscript-string">&quot;stop at \&quot;%d%f\&quot;:%l&quot;</span>
				  <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
    (gud-def gud-finish <span class="enscript-string">&quot;return&quot;</span>  <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>)
    (gud-def gud-up	<span class="enscript-string">&quot;up %p; printf \&quot;\032\032%1d:\&quot;,(int)$curline;file\n&quot;</span>
	     <span class="enscript-string">&quot;&lt;&quot;</span> <span class="enscript-string">&quot;Up (numeric arg) stack frames.&quot;</span>)
    (gud-def gud-down <span class="enscript-string">&quot;down %p; printf \&quot;\032\032%1d:\&quot;,(int)$curline;file\n&quot;</span>
	     <span class="enscript-string">&quot;&gt;&quot;</span> <span class="enscript-string">&quot;Down (numeric arg) stack frames.&quot;</span>)
    <span class="enscript-comment">;; Make dbx give out the source location info that we need.
</span>    (process-send-string (get-buffer-process gud-comint-buffer)
			 <span class="enscript-string">&quot;printf \&quot;\032\032%1d:\&quot;,(int)$curline;file\n&quot;</span>))
   (t
    (gud-def gud-up	<span class="enscript-string">&quot;up %p&quot;</span>   <span class="enscript-string">&quot;&lt;&quot;</span> <span class="enscript-string">&quot;Up (numeric arg) stack frames.&quot;</span>)
    (gud-def gud-down	<span class="enscript-string">&quot;down %p&quot;</span> <span class="enscript-string">&quot;&gt;&quot;</span> <span class="enscript-string">&quot;Down (numeric arg) stack frames.&quot;</span>)
    (gud-def gud-break <span class="enscript-string">&quot;file \&quot;%d%f\&quot;\nstop at %l&quot;</span>
				  <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
    (<span class="enscript-keyword">if</span> gud-dbx-use-stopformat-p
	(process-send-string (get-buffer-process gud-comint-buffer)
			     <span class="enscript-string">&quot;set $stopformat=1\n&quot;</span>))))

  (gud-def gud-remove <span class="enscript-string">&quot;clear %l&quot;</span>  <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;step %p&quot;</span>   <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one line with display.&quot;</span>)
  (gud-def gud-stepi  <span class="enscript-string">&quot;stepi %p&quot;</span>  <span class="enscript-string">&quot;\C-i&quot;</span> <span class="enscript-string">&quot;Step one instruction with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;next %p&quot;</span>   <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-nexti  <span class="enscript-string">&quot;nexti %p&quot;</span>   nil  <span class="enscript-string">&quot;Step one instruction (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;cont&quot;</span>      <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;print %e&quot;</span>  <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate C expression at point.&quot;</span>)
  (gud-def gud-run    <span class="enscript-string">&quot;run&quot;</span>	     nil    <span class="enscript-string">&quot;Run the program.&quot;</span>)

  (setq comint-prompt-regexp  <span class="enscript-string">&quot;^[^)\n]*dbx) *&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'dbx-mode-hook)
  )

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; xdb (HP PARISC debugger) functions
</span>
<span class="enscript-comment">;; History of argument lists passed to xdb.
</span>(defvar gud-xdb-history nil)

(defcustom gud-xdb-directories nil
  <span class="enscript-string">&quot;*A list of directories that xdb should search for source code.
If nil, only source files in the program directory
will be known to xdb.

The file names should be absolute, or relative to the directory
containing the executable being debugged.&quot;</span>
  <span class="enscript-reference">:type</span> '(choice (const <span class="enscript-reference">:tag</span> <span class="enscript-string">&quot;Current Directory&quot;</span> nil)
		 (repeat <span class="enscript-reference">:value</span> (<span class="enscript-string">&quot;&quot;</span>)
			 directory))
  <span class="enscript-reference">:group</span> 'gud)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-xdb-massage-args</span> (file args)
  (nconc (<span class="enscript-keyword">let</span> ((directories gud-xdb-directories)
	       (result nil))
	   (<span class="enscript-keyword">while</span> directories
	     (setq result (cons (car directories) (cons <span class="enscript-string">&quot;-d&quot;</span> result)))
	     (setq directories (cdr directories)))
	   (nreverse result))
	 args))

<span class="enscript-comment">;; xdb does not print the lines all at once, so we have to accumulate them
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-xdb-marker-filter</span> (string)
  (<span class="enscript-keyword">let</span> (result)
    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> (string-match comint-prompt-regexp string)
	    (string-match <span class="enscript-string">&quot;.*\012&quot;</span> string))
	(setq result (concat gud-marker-acc string)
	      gud-marker-acc <span class="enscript-string">&quot;&quot;</span>)
      (setq gud-marker-acc (concat gud-marker-acc string)))
    (<span class="enscript-keyword">if</span> result
	(<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> (string-match <span class="enscript-string">&quot;\\([^\n \t:]+\\): [^:]+: \\([0-9]+\\)[: ]&quot;</span>
			      result)
                (string-match <span class="enscript-string">&quot;[^: \t]+:[ \t]+\\([^:]+\\): [^:]+: \\([0-9]+\\):&quot;</span>
                              result))
            (<span class="enscript-keyword">let</span> ((line (string-to-number (match-string 2 result)))
                  (file (gud-file-name (match-string 1 result))))
              (<span class="enscript-keyword">if</span> file
                  (setq gud-last-frame (cons file line))))))
    (<span class="enscript-keyword">or</span> result <span class="enscript-string">&quot;&quot;</span>)))

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">xdb</span> (command-line)
  <span class="enscript-string">&quot;Run xdb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.

You can set the variable `gud-xdb-directories' to a list of program source
directories if your program contains sources from more than one directory.&quot;</span>
  (interactive (list (gud-query-cmdline 'xdb)))

  (gud-common-init command-line 'gud-xdb-massage-args
		   'gud-xdb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'xdb)

  (gud-def gud-break  <span class="enscript-string">&quot;b %f:%l&quot;</span>    <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-tbreak <span class="enscript-string">&quot;b %f:%l\\t&quot;</span> <span class="enscript-string">&quot;\C-t&quot;</span>
	   <span class="enscript-string">&quot;Set temporary breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;db&quot;</span>         <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;s %p&quot;</span>       <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one line with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;S %p&quot;</span>       <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;c&quot;</span>          <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-up     <span class="enscript-string">&quot;up %p&quot;</span>      <span class="enscript-string">&quot;&lt;&quot;</span>    <span class="enscript-string">&quot;Up (numeric arg) stack frames.&quot;</span>)
  (gud-def gud-down   <span class="enscript-string">&quot;down %p&quot;</span>    <span class="enscript-string">&quot;&gt;&quot;</span>    <span class="enscript-string">&quot;Down (numeric arg) stack frames.&quot;</span>)
  (gud-def gud-finish <span class="enscript-string">&quot;bu\\t&quot;</span>      <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;p %e&quot;</span>       <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate C expression at point.&quot;</span>)

  (setq comint-prompt-regexp  <span class="enscript-string">&quot;^&gt;&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'xdb-mode-hook))

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; perldb functions
</span>
<span class="enscript-comment">;; History of argument lists passed to perldb.
</span>(defvar gud-perldb-history nil)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-perldb-massage-args</span> (file args)
  <span class="enscript-string">&quot;Convert a command line as would be typed normally to run perldb
into one that invokes an Emacs-enabled debugging session.
\&quot;-emacs\&quot; is inserted where it will be $ARGV[0] (see perl5db.pl).&quot;</span>
  <span class="enscript-comment">;; FIXME: what if the command is `make perldb' and doesn't accept those extra
</span>  <span class="enscript-comment">;; arguments ?
</span>  (<span class="enscript-keyword">let</span>* ((new-args nil)
	 (seen-e nil)
	 (shift (<span class="enscript-keyword">lambda</span> () (push (pop args) new-args))))

    <span class="enscript-comment">;; Pass all switches and -e scripts through.
</span>    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> args
		(string-match <span class="enscript-string">&quot;^-&quot;</span> (car args))
		(not (equal <span class="enscript-string">&quot;-&quot;</span> (car args)))
		(not (equal <span class="enscript-string">&quot;--&quot;</span> (car args))))
      (<span class="enscript-keyword">when</span> (equal <span class="enscript-string">&quot;-e&quot;</span> (car args))
	<span class="enscript-comment">;; -e goes with the next arg, so shift one extra.
</span>	(<span class="enscript-keyword">or</span> (funcall shift)
	    <span class="enscript-comment">;; -e as the last arg is an error in Perl.
</span>	    (error <span class="enscript-string">&quot;No code specified for -e&quot;</span>))
	(setq seen-e t))
      (funcall shift))

    (<span class="enscript-keyword">unless</span> seen-e
      (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">or</span> (not args)
	      (string-match <span class="enscript-string">&quot;^-&quot;</span> (car args)))
	  (error <span class="enscript-string">&quot;Can't use stdin as the script to debug&quot;</span>))
      <span class="enscript-comment">;; This is the program name.
</span>      (funcall shift))

    <span class="enscript-comment">;; If -e specified, make sure there is a -- so -emacs is not taken
</span>    <span class="enscript-comment">;; as -e macs.
</span>    (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> args (equal <span class="enscript-string">&quot;--&quot;</span> (car args)))
	(funcall shift)
      (<span class="enscript-keyword">and</span> seen-e (push <span class="enscript-string">&quot;--&quot;</span> new-args)))

    (push <span class="enscript-string">&quot;-emacs&quot;</span> new-args)
    (<span class="enscript-keyword">while</span> args
      (funcall shift))

    (nreverse new-args)))

<span class="enscript-comment">;; There's no guarantee that Emacs will hand the filter the entire
</span><span class="enscript-comment">;; marker at once; it could be broken up across several strings.  We
</span><span class="enscript-comment">;; might even receive a big chunk with several markers in it.  If we
</span><span class="enscript-comment">;; receive a chunk of text which looks like it might contain the
</span><span class="enscript-comment">;; beginning of a marker, we save it here between calls to the
</span><span class="enscript-comment">;; filter.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-perldb-marker-filter</span> (string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  (<span class="enscript-keyword">let</span> ((output <span class="enscript-string">&quot;&quot;</span>))

    <span class="enscript-comment">;; Process all the complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (string-match <span class="enscript-string">&quot;\032\032\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\):.*\n&quot;</span>
			 gud-marker-acc)
      (setq

       <span class="enscript-comment">;; Extract the frame position from the marker.
</span>       gud-last-frame
       (cons (match-string 1 gud-marker-acc)
	     (string-to-number (match-string 3 gud-marker-acc)))

       <span class="enscript-comment">;; Append any text before the marker to the output we're going
</span>       <span class="enscript-comment">;; to return - we don't include the marker in this text.
</span>       output (concat output
		      (substring gud-marker-acc 0 (match-beginning 0)))

       <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    <span class="enscript-comment">;; Does the remaining text look like it might end with the
</span>    <span class="enscript-comment">;; beginning of another marker?  If it does, then keep it in
</span>    <span class="enscript-comment">;; gud-marker-acc until we receive the rest of it.  Since we
</span>    <span class="enscript-comment">;; know the full marker regexp above failed, it's pretty simple to
</span>    <span class="enscript-comment">;; test for marker starts.
</span>    (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;\032.*\\'&quot;</span> gud-marker-acc)
	(<span class="enscript-keyword">progn</span>
	  <span class="enscript-comment">;; Everything before the potential marker start can be output.
</span>	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  <span class="enscript-comment">;; Everything after, we save, to combine with later input.
</span>	  (setq gud-marker-acc
		(substring gud-marker-acc (match-beginning 0))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc <span class="enscript-string">&quot;&quot;</span>))

    output))

(defcustom gud-perldb-command-name <span class="enscript-string">&quot;perl -d&quot;</span>
  <span class="enscript-string">&quot;Default command to execute a Perl script under debugger.&quot;</span>
  <span class="enscript-reference">:type</span> 'string
  <span class="enscript-reference">:group</span> 'gud)

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">perldb</span> (command-line)
  <span class="enscript-string">&quot;Run perldb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.&quot;</span>
  (interactive
   (list (gud-query-cmdline 'perldb
			    (concat (<span class="enscript-keyword">or</span> (buffer-file-name) <span class="enscript-string">&quot;-e 0&quot;</span>) <span class="enscript-string">&quot; &quot;</span>))))

  (gud-common-init command-line 'gud-perldb-massage-args
		   'gud-perldb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'perldb)

  (gud-def gud-break  <span class="enscript-string">&quot;b %l&quot;</span>         <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;B %l&quot;</span>         <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;s&quot;</span>            <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;n&quot;</span>            <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;c&quot;</span>            <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
<span class="enscript-comment">;  (gud-def gud-finish &quot;finish&quot;       &quot;\C-f&quot; &quot;Finish executing current function.&quot;)
</span><span class="enscript-comment">;  (gud-def gud-up     &quot;up %p&quot;        &quot;&lt;&quot; &quot;Up N stack frames (numeric arg).&quot;)
</span><span class="enscript-comment">;  (gud-def gud-down   &quot;down %p&quot;      &quot;&gt;&quot; &quot;Down N stack frames (numeric arg).&quot;)
</span>  (gud-def gud-print  <span class="enscript-string">&quot;p %e&quot;</span>          <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate perl expression at point.&quot;</span>)
  (gud-def gud-until  <span class="enscript-string">&quot;c %l&quot;</span>          <span class="enscript-string">&quot;\C-u&quot;</span> <span class="enscript-string">&quot;Continue to current line.&quot;</span>)


  (setq comint-prompt-regexp <span class="enscript-string">&quot;^  DB&lt;+[0-9]+&gt;+ &quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'perldb-mode-hook))

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; pdb (Python debugger) functions
</span>
<span class="enscript-comment">;; History of argument lists passed to pdb.
</span>(defvar gud-pdb-history nil)

<span class="enscript-comment">;; Last group is for return value, e.g. &quot;&gt; test.py(2)foo()-&gt;None&quot;
</span><span class="enscript-comment">;; Either file or function name may be omitted: &quot;&gt; &lt;string&gt;(0)?()&quot;
</span>(defvar gud-pdb-marker-regexp
  <span class="enscript-string">&quot;^&gt; \\([-a-zA-Z0-9_/.:\\]*\\|&lt;string&gt;\\)(\\([0-9]+\\))\\([a-zA-Z0-9_]*\\|\\?\\|&lt;module&gt;\\)()\\(-&gt;[^\n]*\\)?\n&quot;</span>)
(defvar gud-pdb-marker-regexp-file-group 1)
(defvar gud-pdb-marker-regexp-line-group 2)
(defvar gud-pdb-marker-regexp-fnname-group 3)

(defvar gud-pdb-marker-regexp-start <span class="enscript-string">&quot;^&gt; &quot;</span>)

<span class="enscript-comment">;; There's no guarantee that Emacs will hand the filter the entire
</span><span class="enscript-comment">;; marker at once; it could be broken up across several strings.  We
</span><span class="enscript-comment">;; might even receive a big chunk with several markers in it.  If we
</span><span class="enscript-comment">;; receive a chunk of text which looks like it might contain the
</span><span class="enscript-comment">;; beginning of a marker, we save it here between calls to the
</span><span class="enscript-comment">;; filter.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-pdb-marker-filter</span> (string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  (<span class="enscript-keyword">let</span> ((output <span class="enscript-string">&quot;&quot;</span>))

    <span class="enscript-comment">;; Process all the complete markers in this chunk.
</span>    (<span class="enscript-keyword">while</span> (string-match gud-pdb-marker-regexp gud-marker-acc)
      (setq

       <span class="enscript-comment">;; Extract the frame position from the marker.
</span>       gud-last-frame
       (<span class="enscript-keyword">let</span> ((file (match-string gud-pdb-marker-regexp-file-group
				 gud-marker-acc))
	     (line (string-to-number
		    (match-string gud-pdb-marker-regexp-line-group
				  gud-marker-acc))))
	 (<span class="enscript-keyword">if</span> (string-equal file <span class="enscript-string">&quot;&lt;string&gt;&quot;</span>)
	     gud-last-frame
	   (cons file line)))

       <span class="enscript-comment">;; Output everything instead of the below
</span>       output (concat output (substring gud-marker-acc 0 (match-end 0)))
<span class="enscript-comment">;;	  ;; Append any text before the marker to the output we're going
</span><span class="enscript-comment">;;	  ;; to return - we don't include the marker in this text.
</span><span class="enscript-comment">;;	  output (concat output
</span><span class="enscript-comment">;;		      (substring gud-marker-acc 0 (match-beginning 0)))
</span>
       <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    <span class="enscript-comment">;; Does the remaining text look like it might end with the
</span>    <span class="enscript-comment">;; beginning of another marker?  If it does, then keep it in
</span>    <span class="enscript-comment">;; gud-marker-acc until we receive the rest of it.  Since we
</span>    <span class="enscript-comment">;; know the full marker regexp above failed, it's pretty simple to
</span>    <span class="enscript-comment">;; test for marker starts.
</span>    (<span class="enscript-keyword">if</span> (string-match gud-pdb-marker-regexp-start gud-marker-acc)
	(<span class="enscript-keyword">progn</span>
	  <span class="enscript-comment">;; Everything before the potential marker start can be output.
</span>	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  <span class="enscript-comment">;; Everything after, we save, to combine with later input.
</span>	  (setq gud-marker-acc
		(substring gud-marker-acc (match-beginning 0))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc <span class="enscript-string">&quot;&quot;</span>))

    output))

(defcustom gud-pdb-command-name <span class="enscript-string">&quot;pdb&quot;</span>
  <span class="enscript-string">&quot;File name for executing the Python debugger.
This should be an executable on your path, or an absolute file name.&quot;</span>
  <span class="enscript-reference">:type</span> 'string
  <span class="enscript-reference">:group</span> 'gud)

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">pdb</span> (command-line)
  <span class="enscript-string">&quot;Run pdb on program FILE in buffer `*gud-FILE*'.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger.&quot;</span>
  (interactive
   (list (gud-query-cmdline 'pdb)))

  (gud-common-init command-line nil 'gud-pdb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'pdb)

  (gud-def gud-break  <span class="enscript-string">&quot;break %f:%l&quot;</span>  <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;clear %f:%l&quot;</span>  <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;step&quot;</span>         <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;next&quot;</span>         <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;continue&quot;</span>     <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-finish <span class="enscript-string">&quot;return&quot;</span>       <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Finish executing current function.&quot;</span>)
  (gud-def gud-up     <span class="enscript-string">&quot;up&quot;</span>           <span class="enscript-string">&quot;&lt;&quot;</span> <span class="enscript-string">&quot;Up one stack frame.&quot;</span>)
  (gud-def gud-down   <span class="enscript-string">&quot;down&quot;</span>         <span class="enscript-string">&quot;&gt;&quot;</span> <span class="enscript-string">&quot;Down one stack frame.&quot;</span>)
  (gud-def gud-print  <span class="enscript-string">&quot;p %e&quot;</span>         <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate Python expression at point.&quot;</span>)
  <span class="enscript-comment">;; Is this right?
</span>  (gud-def gud-statement <span class="enscript-string">&quot;! %e&quot;</span>      <span class="enscript-string">&quot;\C-e&quot;</span> <span class="enscript-string">&quot;Execute Python statement at point.&quot;</span>)

  <span class="enscript-comment">;; (setq comint-prompt-regexp &quot;^(.*pdb[+]?) *&quot;)
</span>  (setq comint-prompt-regexp <span class="enscript-string">&quot;^(Pdb) *&quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'pdb-mode-hook))

<span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; JDB support.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; AUTHOR:	Derek Davies &lt;<a href="mailto:ddavies@world.std.com">ddavies@world.std.com</a>&gt;
</span><span class="enscript-comment">;;		Zoltan Kemenczy &lt;<a href="mailto:zoltan@ieee.org">zoltan@ieee.org</a>;<a href="mailto:zkemenczy@rim.net">zkemenczy@rim.net</a>&gt;
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; CREATED:	Sun Feb 22 10:46:38 1998 Derek Davies.
</span><span class="enscript-comment">;; UPDATED:	Nov 11, 2001 Zoltan Kemenczy
</span><span class="enscript-comment">;;              Dec 10, 2002 Zoltan Kemenczy - added nested class support
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; INVOCATION NOTES:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; You invoke jdb-mode with:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    M-x jdb &lt;enter&gt;
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; It responds with:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    Run jdb (like this): jdb
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; type any jdb switches followed by the name of the class you'd like to debug.
</span><span class="enscript-comment">;; Supply a fully qualfied classname (these do not have the &quot;.class&quot; extension)
</span><span class="enscript-comment">;; for the name of the class to debug (e.g. &quot;COM.the-kind.ddavies.CoolClass&quot;).
</span><span class="enscript-comment">;; See the known problems section below for restrictions when specifying jdb
</span><span class="enscript-comment">;; command line switches (search forward for '-classpath').
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; You should see something like the following:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    Current directory is ~/src/java/hello/
</span><span class="enscript-comment">;;    Initializing jdb...
</span><span class="enscript-comment">;;    0xed2f6628:class(hello)
</span><span class="enscript-comment">;;    &gt;
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; To set an initial breakpoint try:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    &gt; stop in hello.main
</span><span class="enscript-comment">;;    Breakpoint set in hello.main
</span><span class="enscript-comment">;;    &gt;
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; To execute the program type:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    &gt; run
</span><span class="enscript-comment">;;    run hello
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;    Breakpoint hit: running ...
</span><span class="enscript-comment">;;    hello.main (hello:12)
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Type M-n to step over the current line and M-s to step into it.  That,
</span><span class="enscript-comment">;; along with the JDB 'help' command should get you started.  The 'quit'
</span><span class="enscript-comment">;; JDB command will get out out of the debugger.  There is some truly
</span><span class="enscript-comment">;; pathetic JDB documentation available at:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;;     <a href="http://java.sun.com/products/jdk/1.1/debugging/">http://java.sun.com/products/jdk/1.1/debugging/</a>
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; KNOWN PROBLEMS AND FIXME's:
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Not sure what happens with inner classes ... haven't tried them.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Does not grok UNICODE id's.  Only ASCII id's are supported.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; You must not put whitespace between &quot;-classpath&quot; and the path to
</span><span class="enscript-comment">;; search for java classes even though it is required when invoking jdb
</span><span class="enscript-comment">;; from the command line.  See gud-jdb-massage-args for details.
</span><span class="enscript-comment">;; The same applies for &quot;-sourcepath&quot;.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Note: The following applies only if `gud-jdb-use-classpath' is nil;
</span><span class="enscript-comment">;; refer to the documentation of `gud-jdb-use-classpath' and
</span><span class="enscript-comment">;; `gud-jdb-classpath',`gud-jdb-sourcepath' variables for information
</span><span class="enscript-comment">;; on using the classpath for locating java source files.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; If any of the source files in the directories listed in
</span><span class="enscript-comment">;; gud-jdb-directories won't parse you'll have problems.  Make sure
</span><span class="enscript-comment">;; every file ending in &quot;.java&quot; in these directories parses without error.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; All the .java files in the directories in gud-jdb-directories are
</span><span class="enscript-comment">;; syntactically analyzed each time gud jdb is invoked.  It would be
</span><span class="enscript-comment">;; nice to keep as much information as possible between runs.  It would
</span><span class="enscript-comment">;; be really nice to analyze the files only as neccessary (when the
</span><span class="enscript-comment">;; source needs to be displayed.)  I'm not sure to what extent the former
</span><span class="enscript-comment">;; can be accomplished and I'm not sure the latter can be done at all
</span><span class="enscript-comment">;; since I don't know of any general way to tell which .class files are
</span><span class="enscript-comment">;; defined by which .java file without analyzing all the .java files.
</span><span class="enscript-comment">;; If anyone knows why JavaSoft didn't put the source file names in
</span><span class="enscript-comment">;; debuggable .class files please clue me in so I find something else
</span><span class="enscript-comment">;; to be spiteful and bitter about.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; ======================================================================
</span><span class="enscript-comment">;; gud jdb variables and functions
</span>
(defcustom gud-jdb-command-name <span class="enscript-string">&quot;jdb&quot;</span>
  <span class="enscript-string">&quot;Command that executes the Java debugger.&quot;</span>
  <span class="enscript-reference">:type</span> 'string
  <span class="enscript-reference">:group</span> 'gud)

(defcustom gud-jdb-use-classpath t
  <span class="enscript-string">&quot;If non-nil, search for Java source files in classpath directories.
The list of directories to search is the value of `gud-jdb-classpath'.
The file pathname is obtained by converting the fully qualified
class information output by jdb to a relative pathname and appending
it to `gud-jdb-classpath' element by element until a match is found.

This method has a significant jdb startup time reduction advantage
since it does not require the scanning of all `gud-jdb-directories'
and parsing all Java files for class information.

Set to nil to use `gud-jdb-directories' to scan java sources for
class information on jdb startup (original method).&quot;</span>
  <span class="enscript-reference">:type</span> 'boolean
  <span class="enscript-reference">:group</span> 'gud)

(defvar gud-jdb-classpath nil
  <span class="enscript-string">&quot;Java/jdb classpath directories list.
If `gud-jdb-use-classpath' is non-nil, gud-jdb derives the `gud-jdb-classpath'
list automatically using the following methods in sequence
\(with subsequent successful steps overriding the results of previous
steps):

1) Read the CLASSPATH environment variable,
2) Read any \&quot;-classpath\&quot; argument used to run jdb,
   or detected in jdb output (e.g. if jdb is run by a script
   that echoes the actual jdb command before starting jdb),
3) Send a \&quot;classpath\&quot; command to jdb and scan jdb output for
   classpath information if jdb is invoked with an \&quot;-attach\&quot; (to
   an already running VM) argument (This case typically does not
   have a \&quot;-classpath\&quot; command line argument - that is provided
   to the VM when it is started).

Note that method 3 cannot be used with oldjdb (or Java 1 jdb) since
those debuggers do not support the classpath command.  Use 1) or 2).&quot;</span>)

(defvar gud-jdb-sourcepath nil
  <span class="enscript-string">&quot;Directory list provided by an (optional) \&quot;-sourcepath\&quot; option to jdb.
This list is prepended to `gud-jdb-classpath' to form the complete
list of directories searched for source files.&quot;</span>)

(defvar gud-marker-acc-max-length 4000
  <span class="enscript-string">&quot;Maximum number of debugger output characters to keep.
This variable limits the size of `gud-marker-acc' which holds
the most recent debugger output history while searching for
source file information.&quot;</span>)

(defvar gud-jdb-history nil
  <span class="enscript-string">&quot;History of argument lists passed to jdb.&quot;</span>)


<span class="enscript-comment">;; List of Java source file directories.
</span>(defvar gud-jdb-directories (list <span class="enscript-string">&quot;.&quot;</span>)
  <span class="enscript-string">&quot;*A list of directories that gud jdb should search for source code.
The file names should be absolute, or relative to the current
directory.

The set of .java files residing in the directories listed are
syntactically analyzed to determine the classes they define and the
packages in which these classes belong.  In this way gud jdb maps the
package-qualified class names output by the jdb debugger to the source
file from which the class originated.  This allows gud mode to keep
the source code display in sync with the debugging session.&quot;</span>)

(defvar gud-jdb-source-files nil
  <span class="enscript-string">&quot;List of the java source files for this debugging session.&quot;</span>)

<span class="enscript-comment">;; Association list of fully qualified class names (package + class name)
</span><span class="enscript-comment">;; and their source files.
</span>(defvar gud-jdb-class-source-alist nil
  <span class="enscript-string">&quot;Association list of fully qualified class names and source files.&quot;</span>)

<span class="enscript-comment">;; This is used to hold a source file during analysis.
</span>(defvar gud-jdb-analysis-buffer nil)

(defvar gud-jdb-classpath-string nil
  <span class="enscript-string">&quot;Holds temporary classpath values.&quot;</span>)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-build-source-files-list</span> (path extn)
  <span class="enscript-string">&quot;Return a list of java source files (absolute paths).
PATH gives the directories in which to search for files with
extension EXTN.  Normally EXTN is given as the regular expression
 \&quot;\\.java$\&quot; .&quot;</span>
  (apply 'nconc (mapcar (<span class="enscript-keyword">lambda</span> (d)
			  (<span class="enscript-keyword">when</span> (file-directory-p d)
			    (directory-files d t extn nil)))
			path)))

<span class="enscript-comment">;; Move point past whitespace.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-whitespace</span> ()
  (skip-chars-forward <span class="enscript-string">&quot; \n\r\t\014&quot;</span>))

<span class="enscript-comment">;; Move point past a &quot;// &lt;eol&gt;&quot; type of comment.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-single-line-comment</span> ()
  (end-of-line))

<span class="enscript-comment">;; Move point past a &quot;/* */&quot; or &quot;/** */&quot; type of comment.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-traditional-or-documentation-comment</span> ()
  (forward-char 2)
  (<span class="enscript-keyword">catch</span> 'break
    (<span class="enscript-keyword">while</span> (not (eobp))
      (<span class="enscript-keyword">if</span> (eq (following-char) ?*)
	  (<span class="enscript-keyword">progn</span>
	    (forward-char)
	    (<span class="enscript-keyword">if</span> (not (eobp))
		(<span class="enscript-keyword">if</span> (eq (following-char) ?/)
		    (<span class="enscript-keyword">progn</span>
		      (forward-char)
		      (<span class="enscript-keyword">throw</span> 'break nil)))))
	(forward-char)))))

<span class="enscript-comment">;; Move point past any number of consecutive whitespace chars and/or comments.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-whitespace-and-comments</span> ()
  (gud-jdb-skip-whitespace)
  (<span class="enscript-keyword">catch</span> 'done
    (<span class="enscript-keyword">while</span> t
      (<span class="enscript-keyword">cond</span>
       ((looking-at <span class="enscript-string">&quot;//&quot;</span>)
	(gud-jdb-skip-single-line-comment)
	(gud-jdb-skip-whitespace))
       ((looking-at <span class="enscript-string">&quot;/\\*&quot;</span>)
	(gud-jdb-skip-traditional-<span class="enscript-keyword">or</span>-documentation-comment)
	(gud-jdb-skip-whitespace))
       (t (<span class="enscript-keyword">throw</span> 'done nil))))))

<span class="enscript-comment">;; Move point past things that are id-like.  The intent is to skip regular
</span><span class="enscript-comment">;; id's, such as class or interface names as well as package and interface
</span><span class="enscript-comment">;; names.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-id-ish-thing</span> ()
  (skip-chars-forward <span class="enscript-string">&quot;^ /\n\r\t\014,;{&quot;</span>))

<span class="enscript-comment">;; Move point past a string literal.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-string-literal</span> ()
  (forward-char)
  (<span class="enscript-keyword">while</span> (not (<span class="enscript-keyword">cond</span>
	       ((eq (following-char) ?\\)
		(forward-char))
	       ((eq (following-char) ?\042))))
    (forward-char))
  (forward-char))

<span class="enscript-comment">;; Move point past a character literal.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-character-literal</span> ()
  (forward-char)
  (<span class="enscript-keyword">while</span>
      (<span class="enscript-keyword">progn</span>
	(<span class="enscript-keyword">if</span> (eq (following-char) ?\\)
	    (forward-char 2))
	(not (eq (following-char) ?\')))
    (forward-char))
  (forward-char))

<span class="enscript-comment">;; Move point past the following block.  There may be (legal) cruft before
</span><span class="enscript-comment">;; the block's opening brace.  There must be a block or it's the end of life
</span><span class="enscript-comment">;; in petticoat junction.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-skip-block</span> ()

  <span class="enscript-comment">;; Find the begining of the block.
</span>  (<span class="enscript-keyword">while</span>
      (not (eq (following-char) ?{))

    <span class="enscript-comment">;; Skip any constructs that can harbor literal block delimiter
</span>    <span class="enscript-comment">;; characters and/or the delimiters for the constructs themselves.
</span>    (<span class="enscript-keyword">cond</span>
     ((looking-at <span class="enscript-string">&quot;//&quot;</span>)
      (gud-jdb-skip-single-line-comment))
     ((looking-at <span class="enscript-string">&quot;/\\*&quot;</span>)
      (gud-jdb-skip-traditional-<span class="enscript-keyword">or</span>-documentation-comment))
     ((eq (following-char) ?\042)
      (gud-jdb-skip-string-literal))
     ((eq (following-char) ?\')
      (gud-jdb-skip-character-literal))
     (t (forward-char))))

  <span class="enscript-comment">;; Now at the begining of the block.
</span>  (forward-char)

  <span class="enscript-comment">;; Skip over the body of the block as well as the final brace.
</span>  (<span class="enscript-keyword">let</span> ((open-level 1))
    (<span class="enscript-keyword">while</span> (not (eq open-level 0))
      (<span class="enscript-keyword">cond</span>
       ((looking-at <span class="enscript-string">&quot;//&quot;</span>)
	(gud-jdb-skip-single-line-comment))
       ((looking-at <span class="enscript-string">&quot;/\\*&quot;</span>)
	(gud-jdb-skip-traditional-<span class="enscript-keyword">or</span>-documentation-comment))
       ((eq (following-char) ?\042)
	(gud-jdb-skip-string-literal))
       ((eq (following-char) ?\')
	(gud-jdb-skip-character-literal))
       ((eq (following-char) ?{)
	(setq open-level (+ open-level 1))
	(forward-char))
       ((eq (following-char) ?})
	(setq open-level (- open-level 1))
	(forward-char))
       (t (forward-char))))))

<span class="enscript-comment">;; Find the package and class definitions in Java source file FILE.  Assumes
</span><span class="enscript-comment">;; that FILE contains a legal Java program.  BUF is a scratch buffer used
</span><span class="enscript-comment">;; to hold the source during analysis.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-analyze-source</span> (buf file)
  (<span class="enscript-keyword">let</span> ((l nil))
    (set-buffer buf)
    (insert-file-contents file nil nil nil t)
    (goto-char 0)
    (<span class="enscript-keyword">catch</span> 'abort
      (<span class="enscript-keyword">let</span> ((p <span class="enscript-string">&quot;&quot;</span>))
	(<span class="enscript-keyword">while</span> (<span class="enscript-keyword">progn</span>
		 (gud-jdb-skip-whitespace)
		 (not (eobp)))
	  (<span class="enscript-keyword">cond</span>

	   <span class="enscript-comment">;; Any number of semi's following a block is legal.  Move point
</span>	   <span class="enscript-comment">;; past them.  Note that comments and whitespace may be
</span>	   <span class="enscript-comment">;; interspersed as well.
</span>	   ((eq (following-char) ?\073)
	    (forward-char))

	   <span class="enscript-comment">;; Move point past a single line comment.
</span>	   ((looking-at <span class="enscript-string">&quot;//&quot;</span>)
	    (gud-jdb-skip-single-line-comment))

	   <span class="enscript-comment">;; Move point past a traditional or documentation comment.
</span>	   ((looking-at <span class="enscript-string">&quot;/\\*&quot;</span>)
	    (gud-jdb-skip-traditional-<span class="enscript-keyword">or</span>-documentation-comment))

	   <span class="enscript-comment">;; Move point past a package statement, but save the PackageName.
</span>	   ((looking-at <span class="enscript-string">&quot;package&quot;</span>)
	    (forward-char 7)
	    (gud-jdb-skip-whitespace-<span class="enscript-keyword">and</span>-comments)
	    (<span class="enscript-keyword">let</span> ((s (point)))
	      (gud-jdb-skip-id-ish-thing)
	      (setq p (concat (buffer-substring s (point)) <span class="enscript-string">&quot;.&quot;</span>))
	      (gud-jdb-skip-whitespace-<span class="enscript-keyword">and</span>-comments)
	      (<span class="enscript-keyword">if</span> (eq (following-char) ?\073)
		  (forward-char))))

	   <span class="enscript-comment">;; Move point past an import statement.
</span>	   ((looking-at <span class="enscript-string">&quot;import&quot;</span>)
	    (forward-char 6)
	    (gud-jdb-skip-whitespace-<span class="enscript-keyword">and</span>-comments)
	    (gud-jdb-skip-id-ish-thing)
	    (gud-jdb-skip-whitespace-<span class="enscript-keyword">and</span>-comments)
	    (<span class="enscript-keyword">if</span> (eq (following-char) ?\073)
		(forward-char)))

	   <span class="enscript-comment">;; Move point past the various kinds of ClassModifiers.
</span>	   ((looking-at <span class="enscript-string">&quot;public&quot;</span>)
	    (forward-char 6))
	   ((looking-at <span class="enscript-string">&quot;abstract&quot;</span>)
	    (forward-char 8))
	   ((looking-at <span class="enscript-string">&quot;final&quot;</span>)
	    (forward-char 5))

	   <span class="enscript-comment">;; Move point past a ClassDeclaraction, but save the class
</span>	   <span class="enscript-comment">;; Identifier.
</span>	   ((looking-at <span class="enscript-string">&quot;class&quot;</span>)
	    (forward-char 5)
	    (gud-jdb-skip-whitespace-<span class="enscript-keyword">and</span>-comments)
	    (<span class="enscript-keyword">let</span> ((s (point)))
	      (gud-jdb-skip-id-ish-thing)
	      (setq
	       l (nconc l (list (concat p (buffer-substring s (point)))))))
	    (gud-jdb-skip-block))

	   <span class="enscript-comment">;; Move point past an interface statement.
</span>	   ((looking-at <span class="enscript-string">&quot;interface&quot;</span>)
	    (forward-char 9)
	    (gud-jdb-skip-block))

	   <span class="enscript-comment">;; Anything else means the input is invalid.
</span>	   (t
	    (message <span class="enscript-string">&quot;Error parsing file %s.&quot;</span> file)
	    (<span class="enscript-keyword">throw</span> 'abort nil))))))
    l))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-build-class-source-alist-for-file</span> (file)
  (mapcar
   (<span class="enscript-keyword">lambda</span> (c)
     (cons c file))
   (gud-jdb-analyze-source gud-jdb-analysis-buffer file)))

<span class="enscript-comment">;; Return an alist of fully qualified classes and the source files
</span><span class="enscript-comment">;; holding their definitions.  SOURCES holds a list of all the source
</span><span class="enscript-comment">;; files to examine.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-build-class-source-alist</span> (sources)
  (setq gud-jdb-analysis-buffer (get-buffer-create <span class="enscript-string">&quot; *gud-jdb-scratch*&quot;</span>))
  (<span class="enscript-keyword">prog1</span>
      (apply
       'nconc
       (mapcar
	'gud-jdb-build-class-source-alist-for-file
	sources))
    (kill-buffer gud-jdb-analysis-buffer)
    (setq gud-jdb-analysis-buffer nil)))

<span class="enscript-comment">;; Change what was given in the minibuffer to something that can be used to
</span><span class="enscript-comment">;; invoke the debugger.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-massage-args</span> (file args)
  <span class="enscript-comment">;; The jdb executable must have whitespace between &quot;-classpath&quot; and
</span>  <span class="enscript-comment">;; its value while gud-common-init expects all switch values to
</span>  <span class="enscript-comment">;; follow the switch keyword without intervening whitespace.  We
</span>  <span class="enscript-comment">;; require that when the user enters the &quot;-classpath&quot; switch in the
</span>  <span class="enscript-comment">;; EMACS minibuffer that they do so without the intervening
</span>  <span class="enscript-comment">;; whitespace.  This function adds it back (it's called after
</span>  <span class="enscript-comment">;; gud-common-init).  There are more switches like this (for
</span>  <span class="enscript-comment">;; instance &quot;-host&quot; and &quot;-password&quot;) but I don't care about them
</span>  <span class="enscript-comment">;; yet.
</span>  (<span class="enscript-keyword">if</span> args
      (<span class="enscript-keyword">let</span> (massaged-args user-error)

	(<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> args (not user-error))
	  (<span class="enscript-keyword">cond</span>
	   ((setq user-error (string-match <span class="enscript-string">&quot;-classpath$&quot;</span> (car args))))
	   ((setq user-error (string-match <span class="enscript-string">&quot;-sourcepath$&quot;</span> (car args))))
	   ((string-match <span class="enscript-string">&quot;-classpath\\(.+\\)&quot;</span> (car args))
	    (setq massaged-args
		  (append massaged-args
			  (list <span class="enscript-string">&quot;-classpath&quot;</span>
				(setq gud-jdb-classpath-string
				      (match-string 1 (car args)))))))
	   ((string-match <span class="enscript-string">&quot;-sourcepath\\(.+\\)&quot;</span> (car args))
	    (setq massaged-args
		  (append massaged-args
			  (list <span class="enscript-string">&quot;-sourcepath&quot;</span>
				(setq gud-jdb-sourcepath
				      (match-string 1 (car args)))))))
	   (t (setq massaged-args (append massaged-args (list (car args))))))
	  (setq args (cdr args)))

	<span class="enscript-comment">;; By this point the current directory is all screwed up.  Maybe we
</span>	<span class="enscript-comment">;; could fix things and re-invoke gud-common-init, but for now I think
</span>	<span class="enscript-comment">;; issueing the error is good enough.
</span>	(<span class="enscript-keyword">if</span> user-error
	    (<span class="enscript-keyword">progn</span>
	      (kill-buffer (current-buffer))
	      (error <span class="enscript-string">&quot;Error: Omit whitespace between '-classpath or -sourcepath' and its value&quot;</span>)))
	massaged-args)))

<span class="enscript-comment">;; Search for an association with P, a fully qualified class name, in
</span><span class="enscript-comment">;; gud-jdb-class-source-alist.  The asssociation gives the fully
</span><span class="enscript-comment">;; qualified file name of the source file which produced the class.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-find-source-file</span> (p)
  (cdr (assoc p gud-jdb-class-source-alist)))

<span class="enscript-comment">;; Note: Reset to this value every time a prompt is seen
</span>(defvar gud-jdb-lowest-stack-level 999)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-find-source-using-classpath</span> (p)
  <span class="enscript-string">&quot;Find source file corresponding to fully qualified class P.
Convert P from jdb's output, converted to a pathname
relative to a classpath directory.&quot;</span>
  (<span class="enscript-keyword">save-match-data</span>
    (<span class="enscript-keyword">let</span>
      (<span class="enscript-comment">;; Replace dots with slashes and append &quot;.java&quot; to generate file
</span>       <span class="enscript-comment">;; name relative to classpath
</span>       (filename
	(concat
	 (mapconcat 'identity
		    (split-string
		     <span class="enscript-comment">;; Eliminate any subclass references in the class
</span>		     <span class="enscript-comment">;; name string. These start with a &quot;$&quot;
</span>		     ((<span class="enscript-keyword">lambda</span> (x)
			(<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;$.*&quot;</span> x)
			    (replace-match <span class="enscript-string">&quot;&quot;</span> t t x) p))
		      p)
		     <span class="enscript-string">&quot;\\.&quot;</span>) <span class="enscript-string">&quot;/&quot;</span>)
	 <span class="enscript-string">&quot;.java&quot;</span>))
       (cplist (append gud-jdb-sourcepath gud-jdb-classpath))
       found-file)
    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> cplist
		(not (setq found-file
			   (file-readable-p
			    (concat (car cplist) <span class="enscript-string">&quot;/&quot;</span> filename)))))
      (setq cplist (cdr cplist)))
    (<span class="enscript-keyword">if</span> found-file (concat (car cplist) <span class="enscript-string">&quot;/&quot;</span> filename)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-find-source</span> (string)
  <span class="enscript-string">&quot;Alias for function used to locate source files.
Set to `gud-jdb-find-source-using-classpath' or `gud-jdb-find-source-file'
during jdb initialization depending on the value of
`gud-jdb-use-classpath'.&quot;</span>
  nil)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-parse-classpath-string</span> (string)
  <span class="enscript-string">&quot;Parse the classpath list and convert each item to an absolute pathname.&quot;</span>
  (mapcar (<span class="enscript-keyword">lambda</span> (s) (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;[/\\]$&quot;</span> s)
			  (replace-match <span class="enscript-string">&quot;&quot;</span> nil nil s) s))
	  (mapcar 'file-truename
		  (split-string
		   string
		   (concat <span class="enscript-string">&quot;[ \t\n\r,\&quot;&quot;</span> path-separator <span class="enscript-string">&quot;]+&quot;</span>)))))

<span class="enscript-comment">;; See comentary for other debugger's marker filters - there you will find
</span><span class="enscript-comment">;; important notes about STRING.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-jdb-marker-filter</span> (string)

  <span class="enscript-comment">;; Build up the accumulator.
</span>  (setq gud-marker-acc
	(<span class="enscript-keyword">if</span> gud-marker-acc
	    (concat gud-marker-acc string)
	  string))

  <span class="enscript-comment">;; Look for classpath information until gud-jdb-classpath-string is found
</span>  <span class="enscript-comment">;; (interactive, multiple settings of classpath from jdb
</span>  <span class="enscript-comment">;;  not supported/followed)
</span>  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> gud-jdb-use-classpath
	   (not gud-jdb-classpath-string)
	   (<span class="enscript-keyword">or</span> (string-match <span class="enscript-string">&quot;classpath:[ \t[]+\\([^]]+\\)&quot;</span> gud-marker-acc)
	       (string-match <span class="enscript-string">&quot;-classpath[ \t\&quot;]+\\([^ \&quot;]+\\)&quot;</span> gud-marker-acc)))
      (setq gud-jdb-classpath
	    (gud-jdb-parse-classpath-string
	     (setq gud-jdb-classpath-string
		   (match-string 1 gud-marker-acc)))))

  <span class="enscript-comment">;; We process STRING from left to right.  Each time through the
</span>  <span class="enscript-comment">;; following loop we process at most one marker. After we've found a
</span>  <span class="enscript-comment">;; marker, delete gud-marker-acc up to and including the match
</span>  (<span class="enscript-keyword">let</span> (file-found)
    <span class="enscript-comment">;; Process each complete marker in the input.
</span>    (<span class="enscript-keyword">while</span>

	<span class="enscript-comment">;; Do we see a marker?
</span>	(string-match
	 <span class="enscript-comment">;; jdb puts out a string of the following form when it
</span>	 <span class="enscript-comment">;; hits a breakpoint:
</span>	 <span class="enscript-comment">;;
</span>	 <span class="enscript-comment">;;	&lt;fully-qualified-class&gt;&lt;method&gt; (&lt;class&gt;:&lt;line-number&gt;)
</span>	 <span class="enscript-comment">;;
</span>	 <span class="enscript-comment">;; &lt;fully-qualified-class&gt;'s are composed of Java ID's
</span>	 <span class="enscript-comment">;; separated by periods.  &lt;method&gt; and &lt;class&gt; are
</span>	 <span class="enscript-comment">;; also Java ID's.  &lt;method&gt; begins with a period and
</span>	 <span class="enscript-comment">;; may contain less-than and greater-than (constructors,
</span>	 <span class="enscript-comment">;; for instance, are called &lt;init&gt; in the symbol table.)
</span>	 <span class="enscript-comment">;; Java ID's begin with a letter followed by letters
</span>	 <span class="enscript-comment">;; and/or digits.  The set of letters includes underscore
</span>	 <span class="enscript-comment">;; and dollar sign.
</span>	 <span class="enscript-comment">;;
</span>	 <span class="enscript-comment">;; The first group matches &lt;fully-qualified-class&gt;,
</span>	 <span class="enscript-comment">;; the second group matches &lt;class&gt; and the third group
</span>	 <span class="enscript-comment">;; matches &lt;line-number&gt;.  We don't care about using
</span>	 <span class="enscript-comment">;; &lt;method&gt; so we don't &quot;group&quot; it.
</span>	 <span class="enscript-comment">;;
</span>	 <span class="enscript-comment">;; FIXME: Java ID's are UNICODE strings, this matches ASCII
</span>	 <span class="enscript-comment">;; ID's only.
</span>         <span class="enscript-comment">;;
</span>         <span class="enscript-comment">;; The &quot;.,&quot; in the last square-bracket are necessary because
</span>         <span class="enscript-comment">;; of Sun's total disrespect for backwards compatibility in
</span>         <span class="enscript-comment">;; reported line numbers from jdb - starting in 1.4.0 they
</span>         <span class="enscript-comment">;; print line numbers using LOCALE, inserting a comma or a
</span>         <span class="enscript-comment">;; period at the thousands positions (how ingenious!).
</span>
	 <span class="enscript-string">&quot;\\(\\[[0-9]+] \\)*\\([a-zA-Z0-9.$_]+\\)\\.[a-zA-Z0-9$_&lt;&gt;(),]+ \
\\(([a-zA-Z0-9.$_]+:\\|line=\\)\\([0-9.,]+\\)&quot;</span>
	 gud-marker-acc)

      <span class="enscript-comment">;; A good marker is one that:
</span>      <span class="enscript-comment">;; 1) does not have a &quot;[n] &quot; prefix (not part of a stack backtrace)
</span>      <span class="enscript-comment">;; 2) does have an &quot;[n] &quot; prefix and n is the lowest prefix seen
</span>      <span class="enscript-comment">;;    since the last prompt
</span>      <span class="enscript-comment">;; Figure out the line on which to position the debugging arrow.
</span>      <span class="enscript-comment">;; Return the info as a cons of the form:
</span>      <span class="enscript-comment">;;
</span>      <span class="enscript-comment">;;     (&lt;file-name&gt; . &lt;line-number&gt;) .
</span>      (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">if</span> (match-beginning 1)
	      (<span class="enscript-keyword">let</span> (n)
		(setq n (string-to-number (substring
					gud-marker-acc
					(1+ (match-beginning 1))
					(- (match-end 1) 2))))
		(<span class="enscript-keyword">if</span> (&lt; n gud-jdb-lowest-stack-level)
		    (<span class="enscript-keyword">progn</span> (setq gud-jdb-lowest-stack-level n) t)))
	    t)
	  (<span class="enscript-keyword">if</span> (setq file-found
		    (gud-jdb-find-source (match-string 2 gud-marker-acc)))
	      (setq gud-last-frame
		    (cons file-found
			  (string-to-number
			   (<span class="enscript-keyword">let</span>
                               ((numstr (match-string 4 gud-marker-acc)))
                             (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;[.,]&quot;</span> numstr)
                                 (replace-match <span class="enscript-string">&quot;&quot;</span> nil nil numstr)
                               numstr)))))
	    (message <span class="enscript-string">&quot;Could not find source file.&quot;</span>)))

      <span class="enscript-comment">;; Set the accumulator to the remaining text.
</span>      (setq gud-marker-acc (substring gud-marker-acc (match-end 0))))

    (<span class="enscript-keyword">if</span> (string-match comint-prompt-regexp gud-marker-acc)
	(setq gud-jdb-lowest-stack-level 999)))

  <span class="enscript-comment">;; Do not allow gud-marker-acc to grow without bound. If the source
</span>  <span class="enscript-comment">;; file information is not within the last 3/4
</span>  <span class="enscript-comment">;; gud-marker-acc-max-length characters, well,...
</span>  (<span class="enscript-keyword">if</span> (&gt; (length gud-marker-acc) gud-marker-acc-max-length)
      (setq gud-marker-acc
	    (substring gud-marker-acc
		       (- (/ (* gud-marker-acc-max-length 3) 4)))))

  <span class="enscript-comment">;; We don't filter any debugger output so just return what we were given.
</span>  string)

(defvar gud-jdb-command-name <span class="enscript-string">&quot;jdb&quot;</span> <span class="enscript-string">&quot;Command that executes the Java debugger.&quot;</span>)

<span class="enscript-comment">;;;###autoload
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">jdb</span> (command-line)
  <span class="enscript-string">&quot;Run jdb with command line COMMAND-LINE in a buffer.
The buffer is named \&quot;*gud*\&quot; if no initial class is given or
\&quot;*gud-&lt;initial-class-basename&gt;*\&quot; if there is.  If the \&quot;-classpath\&quot;
switch is given, omit all whitespace between it and its value.

See `gud-jdb-use-classpath' and `gud-jdb-classpath' documentation for
information on how jdb accesses source files.  Alternatively (if
`gud-jdb-use-classpath' is nil), see `gud-jdb-directories' for the
original source file access method.

For general information about commands available to control jdb from
gud, see `gud-mode'.&quot;</span>
  (interactive
   (list (gud-query-cmdline 'jdb)))
  (setq gud-jdb-classpath nil)
  (setq gud-jdb-sourcepath nil)

  <span class="enscript-comment">;; Set gud-jdb-classpath from the CLASSPATH environment variable,
</span>  <span class="enscript-comment">;; if CLASSPATH is set.
</span>  (setq gud-jdb-classpath-string (getenv <span class="enscript-string">&quot;CLASSPATH&quot;</span>))
  (<span class="enscript-keyword">if</span> gud-jdb-classpath-string
      (setq gud-jdb-classpath
	    (gud-jdb-parse-classpath-string gud-jdb-classpath-string)))
  (setq gud-jdb-classpath-string nil)	<span class="enscript-comment">; prepare for next
</span>
  (gud-common-init command-line 'gud-jdb-massage-args
		   'gud-jdb-marker-filter)
  (set (make-local-variable 'gud-minor-mode) 'jdb)

  <span class="enscript-comment">;; If a -classpath option was provided, set gud-jdb-classpath
</span>  (<span class="enscript-keyword">if</span> gud-jdb-classpath-string
      (setq gud-jdb-classpath
	    (gud-jdb-parse-classpath-string gud-jdb-classpath-string)))
  (setq gud-jdb-classpath-string nil)	<span class="enscript-comment">; prepare for next
</span>  <span class="enscript-comment">;; If a -sourcepath option was provided, parse it
</span>  (<span class="enscript-keyword">if</span> gud-jdb-sourcepath
      (setq gud-jdb-sourcepath
	    (gud-jdb-parse-classpath-string gud-jdb-sourcepath)))

  (gud-def gud-break  <span class="enscript-string">&quot;stop at %c:%l&quot;</span> <span class="enscript-string">&quot;\C-b&quot;</span> <span class="enscript-string">&quot;Set breakpoint at current line.&quot;</span>)
  (gud-def gud-remove <span class="enscript-string">&quot;clear %c:%l&quot;</span>   <span class="enscript-string">&quot;\C-d&quot;</span> <span class="enscript-string">&quot;Remove breakpoint at current line&quot;</span>)
  (gud-def gud-step   <span class="enscript-string">&quot;step&quot;</span>          <span class="enscript-string">&quot;\C-s&quot;</span> <span class="enscript-string">&quot;Step one source line with display.&quot;</span>)
  (gud-def gud-next   <span class="enscript-string">&quot;next&quot;</span>          <span class="enscript-string">&quot;\C-n&quot;</span> <span class="enscript-string">&quot;Step one line (skip functions).&quot;</span>)
  (gud-def gud-cont   <span class="enscript-string">&quot;cont&quot;</span>          <span class="enscript-string">&quot;\C-r&quot;</span> <span class="enscript-string">&quot;Continue with display.&quot;</span>)
  (gud-def gud-finish <span class="enscript-string">&quot;step up&quot;</span>       <span class="enscript-string">&quot;\C-f&quot;</span> <span class="enscript-string">&quot;Continue until current method returns.&quot;</span>)
  (gud-def gud-up     <span class="enscript-string">&quot;up\C-Mwhere&quot;</span>   <span class="enscript-string">&quot;&lt;&quot;</span>    <span class="enscript-string">&quot;Up one stack frame.&quot;</span>)
  (gud-def gud-down   <span class="enscript-string">&quot;down\C-Mwhere&quot;</span> <span class="enscript-string">&quot;&gt;&quot;</span>    <span class="enscript-string">&quot;Up one stack frame.&quot;</span>)
  (gud-def gud-run    <span class="enscript-string">&quot;run&quot;</span>           nil    <span class="enscript-string">&quot;Run the program.&quot;</span>) <span class="enscript-comment">;if VM start using jdb
</span>  (gud-def gud-print  <span class="enscript-string">&quot;print %e&quot;</span>  <span class="enscript-string">&quot;\C-p&quot;</span> <span class="enscript-string">&quot;Evaluate Java expression at point.&quot;</span>)


  (setq comint-prompt-regexp <span class="enscript-string">&quot;^&gt; \\|^[^ ]+\\[[0-9]+\\] &quot;</span>)
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'jdb-mode-hook)

  (<span class="enscript-keyword">if</span> gud-jdb-use-classpath
      <span class="enscript-comment">;; Get the classpath information from the debugger
</span>      (<span class="enscript-keyword">progn</span>
	(<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;-attach&quot;</span> command-line)
	    (gud-call <span class="enscript-string">&quot;classpath&quot;</span>))
	(fset 'gud-jdb-find-source
	      'gud-jdb-find-source-using-classpath))

    <span class="enscript-comment">;; Else create and bind the class/source association list as well
</span>    <span class="enscript-comment">;; as the source file list.
</span>    (setq gud-jdb-class-source-alist
	  (gud-jdb-build-class-source-alist
	   (setq gud-jdb-source-files
		 (gud-jdb-build-source-files-list gud-jdb-directories
						  <span class="enscript-string">&quot;\\.java$&quot;</span>))))
    (fset 'gud-jdb-find-source 'gud-jdb-find-source-file)))

<span class="enscript-comment">;;
</span><span class="enscript-comment">;; End of debugger-specific information
</span><span class="enscript-comment">;;
</span>

<span class="enscript-comment">;; When we send a command to the debugger via gud-call, it's annoying
</span><span class="enscript-comment">;; to see the command and the new prompt inserted into the debugger's
</span><span class="enscript-comment">;; buffer; we have other ways of knowing the command has completed.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; If the buffer looks like this:
</span><span class="enscript-comment">;; --------------------
</span><span class="enscript-comment">;; (gdb) set args foo bar
</span><span class="enscript-comment">;; (gdb) -!-
</span><span class="enscript-comment">;; --------------------
</span><span class="enscript-comment">;; (the -!- marks the location of point), and we type `C-x SPC' in a
</span><span class="enscript-comment">;; source file to set a breakpoint, we want the buffer to end up like
</span><span class="enscript-comment">;; this:
</span><span class="enscript-comment">;; --------------------
</span><span class="enscript-comment">;; (gdb) set args foo bar
</span><span class="enscript-comment">;; Breakpoint 1 at 0x92: file make-docfile.c, line 49.
</span><span class="enscript-comment">;; (gdb) -!-
</span><span class="enscript-comment">;; --------------------
</span><span class="enscript-comment">;; Essentially, the old prompt is deleted, and the command's output
</span><span class="enscript-comment">;; and the new prompt take its place.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; Not echoing the command is easy enough; you send it directly using
</span><span class="enscript-comment">;; process-send-string, and it never enters the buffer.  However,
</span><span class="enscript-comment">;; getting rid of the old prompt is trickier; you don't want to do it
</span><span class="enscript-comment">;; when you send the command, since that will result in an annoying
</span><span class="enscript-comment">;; flicker as the prompt is deleted, redisplay occurs while Emacs
</span><span class="enscript-comment">;; waits for a response from the debugger, and the new prompt is
</span><span class="enscript-comment">;; inserted.  Instead, we'll wait until we actually get some output
</span><span class="enscript-comment">;; from the subprocess before we delete the prompt.  If the command
</span><span class="enscript-comment">;; produced no output other than a new prompt, that prompt will most
</span><span class="enscript-comment">;; likely be in the first chunk of output received, so we will delete
</span><span class="enscript-comment">;; the prompt and then replace it with an identical one.  If the
</span><span class="enscript-comment">;; command produces output, the prompt is moving anyway, so the
</span><span class="enscript-comment">;; flicker won't be annoying.
</span><span class="enscript-comment">;;
</span><span class="enscript-comment">;; So - when we want to delete the prompt upon receipt of the next
</span><span class="enscript-comment">;; chunk of debugger output, we position gud-delete-prompt-marker at
</span><span class="enscript-comment">;; the start of the prompt; the process filter will notice this, and
</span><span class="enscript-comment">;; delete all text between it and the process output marker.  If
</span><span class="enscript-comment">;; gud-delete-prompt-marker points nowhere, we leave the current
</span><span class="enscript-comment">;; prompt alone.
</span>(defvar gud-delete-prompt-marker nil)


(put 'gud-mode 'mode-class 'special)

(define-derived-mode gud-mode comint-mode <span class="enscript-string">&quot;Debugger&quot;</span>
  <span class="enscript-string">&quot;Major mode for interacting with an inferior debugger process.

   You start it up with one of the commands M-x gdb, M-x sdb, M-x dbx,
M-x perldb, M-x xdb, M-x jdb, or M-x lldb.  Each entry point finishes by
executing a hook; `gdb-mode-hook', `sdb-mode-hook', `dbx-mode-hook',
`perldb-mode-hook', `xdb-mode-hook', `jdb-mode-hook', or `lldb-mode-hook'
respectively.

After startup, the following commands are available in both the GUD
interaction buffer and any source buffer GUD visits due to a breakpoint stop
or step operation:

\\[gud-break] sets a breakpoint at the current file and line.  In the
GUD buffer, the current file and line are those of the last breakpoint or
step.  In a source buffer, they are the buffer's file and current line.

\\[gud-remove] removes breakpoints on the current file and line.

\\[gud-refresh] displays in the source window the last line referred to
in the gud buffer.

\\[gud-step], \\[gud-next], and \\[gud-stepi] do a step-one-line,
step-one-line (not entering function calls), and step-one-instruction
and then update the source window with the current file and position.
\\[gud-cont] continues execution.

\\[gud-print] tries to find the largest C lvalue or function-call expression
around point, and sends it to the debugger for value display.

The above commands are common to all supported debuggers except xdb which
does not support stepping instructions.

Under gdb, sdb and xdb, \\[gud-tbreak] behaves exactly like \\[gud-break],
except that the breakpoint is temporary; that is, it is removed when
execution stops on it.

Under gdb, dbx, xdb, and lldb, \\[gud-up] pops up through an enclosing stack
frame.  \\[gud-down] drops back down through one.

If you are using gdb or xdb, \\[gud-finish] runs execution to the return from
the current function and stops.

All the keystrokes above are accessible in the GUD buffer
with the prefix C-c, and in all buffers through the prefix C-x C-a.

All pre-defined functions for which the concept make sense repeat
themselves the appropriate number of times if you give a prefix
argument.

You may use the `gud-def' macro in the initialization hook to define other
commands.

Other commands for interacting with the debugger process are inherited from
comint mode, which see.&quot;</span>
  (setq mode-line-process '(<span class="enscript-string">&quot;:%s&quot;</span>))
  (define-key (current-local-map) <span class="enscript-string">&quot;\C-c\C-l&quot;</span> 'gud-refresh)
  (set (make-local-variable 'gud-last-frame) nil)
  (set (make-local-variable 'tool-bar-map) gud-tool-bar-map)
  (make-local-variable 'comint-prompt-regexp)
  <span class="enscript-comment">;; Don't put repeated commands in command history many times.
</span>  (set (make-local-variable 'comint-input-ignoredups) t)
  (make-local-variable 'paragraph-start)
  (set (make-local-variable 'gud-delete-prompt-marker) (make-marker))
  (add-hook 'kill-buffer-hook 'gud-kill-buffer-hook nil t))

<span class="enscript-comment">;; Cause our buffers to be displayed, by default,
</span><span class="enscript-comment">;; in the selected window.
</span><span class="enscript-comment">;;;###autoload (add-hook 'same-window-regexps &quot;\\*gud-.*\\*\\(\\|&lt;[0-9]+&gt;\\)&quot;)
</span>
(defcustom gud-chdir-before-run t
  <span class="enscript-string">&quot;Non-nil if GUD should `cd' to the debugged executable.&quot;</span>
  <span class="enscript-reference">:group</span> 'gud
  <span class="enscript-reference">:type</span> 'boolean)

(defvar gud-target-name <span class="enscript-string">&quot;--unknown--&quot;</span>
  <span class="enscript-string">&quot;The apparent name of the program being debugged in a gud buffer.&quot;</span>)

<span class="enscript-comment">;; Perform initializations common to all debuggers.
</span><span class="enscript-comment">;; The first arg is the specified command line,
</span><span class="enscript-comment">;; which starts with the program to debug.
</span><span class="enscript-comment">;; The other three args specify the values to use
</span><span class="enscript-comment">;; for local variables in the debugger buffer.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-common-init</span> (command-line massage-args marker-filter
				     &amp;optional find-file)
  (<span class="enscript-keyword">let</span>* ((words (split-string-<span class="enscript-keyword">and</span>-unquote command-line))
	 (program (car words))
	 (dir default-directory)
	 <span class="enscript-comment">;; Extract the file name from WORDS
</span>	 <span class="enscript-comment">;; and put t in its place.
</span>	 <span class="enscript-comment">;; Later on we will put the modified file name arg back there.
</span>	 (file-word (<span class="enscript-keyword">let</span> ((w (cdr words)))
		      (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> w (= ?- (aref (car w) 0)))
			(setq w (cdr w)))
		      (<span class="enscript-keyword">and</span> w
			   (<span class="enscript-keyword">prog1</span> (car w)
			     (setcar w t)))))
	 (file-subst
	  (<span class="enscript-keyword">and</span> file-word (substitute-in-file-name file-word)))
	 (args (cdr words))
	 <span class="enscript-comment">;; If a directory was specified, expand the file name.
</span>	 <span class="enscript-comment">;; Otherwise, don't expand it, so GDB can use the PATH.
</span>	 <span class="enscript-comment">;; A file name without directory is literally valid
</span>	 <span class="enscript-comment">;; only if the file exists in ., and in that case,
</span>	 <span class="enscript-comment">;; omitting the expansion here has no visible effect.
</span>	 (file (<span class="enscript-keyword">and</span> file-word
		    (<span class="enscript-keyword">if</span> (file-name-directory file-subst)
			(expand-file-name file-subst)
		      file-subst)))
	 (filepart (<span class="enscript-keyword">and</span> file-word (concat <span class="enscript-string">&quot;-&quot;</span> (file-name-nondirectory file))))
	 (existing-buffer (get-buffer (concat <span class="enscript-string">&quot;*gud&quot;</span> filepart <span class="enscript-string">&quot;*&quot;</span>))))
    (pop-to-buffer (concat <span class="enscript-string">&quot;*gud&quot;</span> filepart <span class="enscript-string">&quot;*&quot;</span>))
    (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> existing-buffer (get-buffer-process existing-buffer))
      (error <span class="enscript-string">&quot;This program is already being debugged&quot;</span>))
    <span class="enscript-comment">;; Set the dir, in case the buffer already existed with a different dir.
</span>    (setq default-directory dir)
    <span class="enscript-comment">;; Set default-directory to the file's directory.
</span>    (<span class="enscript-keyword">and</span> file-word
	 gud-chdir-before-run
	 <span class="enscript-comment">;; Don't set default-directory if no directory was specified.
</span>	 <span class="enscript-comment">;; In that case, either the file is found in the current directory,
</span>	 <span class="enscript-comment">;; in which case this setq is a no-op,
</span>	 <span class="enscript-comment">;; or it is found by searching PATH,
</span>	 <span class="enscript-comment">;; in which case we don't know what directory it was found in.
</span>	 (file-name-directory file)
	 (setq default-directory (file-name-directory file)))
    (<span class="enscript-keyword">or</span> (bolp) (newline))
    (insert <span class="enscript-string">&quot;Current directory is &quot;</span> default-directory <span class="enscript-string">&quot;\n&quot;</span>)
    <span class="enscript-comment">;; Put the substituted and expanded file name back in its place.
</span>    (<span class="enscript-keyword">let</span> ((w args))
      (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> w (not (eq (car w) t)))
	(setq w (cdr w)))
      (<span class="enscript-keyword">if</span> w
	  (setcar w file)))
    (apply 'make-comint (concat <span class="enscript-string">&quot;gud&quot;</span> filepart) program nil
	   (<span class="enscript-keyword">if</span> massage-args (funcall massage-args file args) args))
    <span class="enscript-comment">;; Since comint clobbered the mode, we don't set it until now.
</span>    (gud-mode)
    (set (make-local-variable 'gud-target-name)
	 (<span class="enscript-keyword">and</span> file-word (file-name-nondirectory file))))
  (set (make-local-variable 'gud-marker-filter) marker-filter)
  (<span class="enscript-keyword">if</span> find-file (set (make-local-variable 'gud-find-file) find-file))
  (setq gud-last-last-frame nil)

  (set-process-filter (get-buffer-process (current-buffer)) 'gud-filter)
  (set-process-sentinel (get-buffer-process (current-buffer)) 'gud-sentinel)
  (gud-set-buffer))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-set-buffer</span> ()
  (<span class="enscript-keyword">when</span> (eq major-mode 'gud-mode)
    (setq gud-comint-buffer (current-buffer))))

(defvar gud-filter-defer-flag nil
  <span class="enscript-string">&quot;Non-nil means don't process anything from the debugger right now.
It is saved for when this flag is not set.&quot;</span>)

<span class="enscript-comment">;; These functions are responsible for inserting output from your debugger
</span><span class="enscript-comment">;; into the buffer.  The hard work is done by the method that is
</span><span class="enscript-comment">;; the value of gud-marker-filter.
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-filter</span> (proc string)
  <span class="enscript-comment">;; Here's where the actual buffer insertion is done
</span>  (<span class="enscript-keyword">let</span> (output process-window)
    (<span class="enscript-keyword">if</span> (buffer-name (process-buffer proc))
	(<span class="enscript-keyword">if</span> gud-filter-defer-flag
	    <span class="enscript-comment">;; If we can't process any text now,
</span>	    <span class="enscript-comment">;; save it for later.
</span>	    (setq gud-filter-pending-text
		  (concat (<span class="enscript-keyword">or</span> gud-filter-pending-text <span class="enscript-string">&quot;&quot;</span>) string))

	  <span class="enscript-comment">;; If we have to ask a question during the processing,
</span>	  <span class="enscript-comment">;; defer any additional text that comes from the debugger
</span>	  <span class="enscript-comment">;; during that time.
</span>	  (<span class="enscript-keyword">let</span> ((gud-filter-defer-flag t))
	    <span class="enscript-comment">;; Process now any text we previously saved up.
</span>	    (<span class="enscript-keyword">if</span> gud-filter-pending-text
		(setq string (concat gud-filter-pending-text string)
		      gud-filter-pending-text nil))

	    (with-current-buffer (process-buffer proc)
	      <span class="enscript-comment">;; If we have been so requested, delete the debugger prompt.
</span>	      (<span class="enscript-keyword">save-restriction</span>
		(widen)
		(<span class="enscript-keyword">if</span> (marker-buffer gud-delete-prompt-marker)
		    (<span class="enscript-keyword">let</span> ((inhibit-read-only t))
		      (delete-region (process-mark proc)
				     gud-delete-prompt-marker)
		      (comint-update-fence)
		      (set-marker gud-delete-prompt-marker nil)))
		<span class="enscript-comment">;; Save the process output, checking for source file markers.
</span>		(setq output (gud-marker-filter string))
		<span class="enscript-comment">;; Check for a filename-and-line number.
</span>		<span class="enscript-comment">;; Don't display the specified file
</span>		<span class="enscript-comment">;; unless (1) point is at or after the position where output appears
</span>		<span class="enscript-comment">;; and (2) this buffer is on the screen.
</span>		(setq process-window
		      (<span class="enscript-keyword">and</span> gud-last-frame
			   (&gt;= (point) (process-mark proc))
			   (get-buffer-window (current-buffer)))))

	      <span class="enscript-comment">;; Let the comint filter do the actual insertion.
</span>	      <span class="enscript-comment">;; That lets us inherit various comint features.
</span>	      (comint-output-filter proc output))

	    <span class="enscript-comment">;; Put the arrow on the source line.
</span>	    <span class="enscript-comment">;; This must be outside of the save-excursion
</span>	    <span class="enscript-comment">;; in case the source file is our current buffer.
</span>	    (<span class="enscript-keyword">if</span> process-window
		(with-selected-window process-window
		  (gud-display-frame))
	      <span class="enscript-comment">;; We have to be in the proper buffer, (process-buffer proc),
</span>	      <span class="enscript-comment">;; but not in a save-excursion, because that would restore point.
</span>	      (with-current-buffer (process-buffer proc)
		(gud-display-frame))))

	  <span class="enscript-comment">;; If we deferred text that arrived during this processing,
</span>	  <span class="enscript-comment">;; handle it now.
</span>	  (<span class="enscript-keyword">if</span> gud-filter-pending-text
	      (gud-filter proc <span class="enscript-string">&quot;&quot;</span>))))))

(defvar gud-minor-mode-type nil)
(defvar gud-overlay-arrow-position nil)
(add-to-list 'overlay-arrow-variable-list 'gud-overlay-arrow-position)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-sentinel</span> (proc msg)
  (<span class="enscript-keyword">cond</span> ((null (buffer-name (process-buffer proc)))
	 <span class="enscript-comment">;; buffer killed
</span>	 <span class="enscript-comment">;; Stop displaying an arrow in a source file.
</span>	 (setq gud-overlay-arrow-position nil)
	 (set-process-buffer proc nil)
	 (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (boundp 'speedbar-frame)
		  (string-equal speedbar-initial-expansion-list-name <span class="enscript-string">&quot;GUD&quot;</span>))
	     (speedbar-change-initial-expansion-list
	      speedbar-previously-used-expansion-list-name))
	 (<span class="enscript-keyword">if</span> (memq gud-minor-mode-type '(gdbmi gdba))
	     (gdb-reset)
	   (gud-reset)))
	((memq (process-status proc) '(signal exit))
	 <span class="enscript-comment">;; Stop displaying an arrow in a source file.
</span>	 (setq gud-overlay-arrow-position nil)
	 (<span class="enscript-keyword">if</span> (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		   '(gdba gdbmi))
	     (gdb-reset)
	   (gud-reset))
	 (<span class="enscript-keyword">let</span>* ((obuf (current-buffer)))
	   <span class="enscript-comment">;; save-excursion isn't the right thing if
</span>	   <span class="enscript-comment">;;  process-buffer is current-buffer
</span>	   (<span class="enscript-keyword">unwind-protect</span>
	       (<span class="enscript-keyword">progn</span>
		 <span class="enscript-comment">;; Write something in the GUD buffer and hack its mode line,
</span>		 (set-buffer (process-buffer proc))
		 <span class="enscript-comment">;; Fix the mode line.
</span>		 (setq mode-line-process
		       (concat <span class="enscript-string">&quot;:&quot;</span>
			       (symbol-name (process-status proc))))
		 (force-mode-line-update)
		 (<span class="enscript-keyword">if</span> (eobp)
		     (insert ?\n mode-name <span class="enscript-string">&quot; &quot;</span> msg)
		   (<span class="enscript-keyword">save-excursion</span>
		     (goto-char (point-max))
		     (insert ?\n mode-name <span class="enscript-string">&quot; &quot;</span> msg)))
		 <span class="enscript-comment">;; If buffer and mode line will show that the process
</span>		 <span class="enscript-comment">;; is dead, we can delete it now.  Otherwise it
</span>		 <span class="enscript-comment">;; will stay around until M-x list-processes.
</span>		 (delete-process proc))
	     <span class="enscript-comment">;; Restore old buffer, but don't restore old point
</span>	     <span class="enscript-comment">;; if obuf is the gud buffer.
</span>	     (set-buffer obuf))))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-kill-buffer-hook</span> ()
  (setq gud-minor-mode-type gud-minor-mode)
  (<span class="enscript-keyword">condition-case</span> nil
      (kill-process (get-buffer-process (current-buffer)))
    (error nil)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-reset</span> ()
  (dolist (buffer (buffer-list))
    (<span class="enscript-keyword">unless</span> (eq buffer gud-comint-buffer)
      (with-current-buffer buffer
	(<span class="enscript-keyword">when</span> gud-minor-mode
	  (setq gud-minor-mode nil)
	  (kill-local-variable 'tool-bar-map))))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-display-frame</span> ()
  <span class="enscript-string">&quot;Find and obey the last filename-and-line marker from the debugger.
Obeying it means displaying in another window the specified file and line.&quot;</span>
  (interactive)
  (<span class="enscript-keyword">when</span> gud-last-frame
    (gud-set-buffer)
    (gud-display-line (car gud-last-frame) (cdr gud-last-frame))
    (setq gud-last-last-frame gud-last-frame
	  gud-last-frame nil)))

<span class="enscript-comment">;; Make sure the file named TRUE-FILE is in a buffer that appears on the screen
</span><span class="enscript-comment">;; and that its line LINE is visible.
</span><span class="enscript-comment">;; Put the overlay-arrow on the line LINE in that buffer.
</span><span class="enscript-comment">;; Most of the trickiness in here comes from wanting to preserve the current
</span><span class="enscript-comment">;; region-restriction if that's possible.  We use an explicit display-buffer
</span><span class="enscript-comment">;; to get around the fact that this is called inside a save-excursion.
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-display-line</span> (true-file line)
  (<span class="enscript-keyword">let</span>* ((last-nonmenu-event t)	 <span class="enscript-comment">; Prevent use of dialog box for questions.
</span>	 (buffer
	  (with-current-buffer gud-comint-buffer
	    (gud-find-file true-file)))
	 (window (<span class="enscript-keyword">and</span> buffer
		      (<span class="enscript-keyword">or</span> (get-buffer-window buffer)
			  (<span class="enscript-keyword">if</span> (memq gud-minor-mode '(gdbmi gdba))
			      (<span class="enscript-keyword">or</span> (<span class="enscript-keyword">if</span> (get-buffer-window buffer 0)
				      (display-buffer buffer nil 0))
				  (<span class="enscript-keyword">unless</span> (gdb-display-source-buffer buffer)
				    (gdb-display-buffer buffer nil))))
			  (display-buffer buffer))))
	 (pos))
    (<span class="enscript-keyword">if</span> buffer
	(<span class="enscript-keyword">progn</span>
	  (with-current-buffer buffer
	    (<span class="enscript-keyword">unless</span> (<span class="enscript-keyword">or</span> (verify-visited-file-modtime buffer) gud-keep-buffer)
		  (<span class="enscript-keyword">if</span> (yes-<span class="enscript-keyword">or</span>-no-p
		       (format <span class="enscript-string">&quot;File %s changed on disk.  Reread from disk? &quot;</span>
			       (buffer-name)))
		      (revert-buffer t t)
		    (setq gud-keep-buffer t)))
	    (<span class="enscript-keyword">save-restriction</span>
	      (widen)
	      (goto-line line)
	      (setq pos (point))
	      (<span class="enscript-keyword">or</span> gud-overlay-arrow-position
		  (setq gud-overlay-arrow-position (make-marker)))
	      (set-marker gud-overlay-arrow-position (point) (current-buffer))
	      <span class="enscript-comment">;; If they turned on hl-line, move the hl-line highlight to
</span>	      <span class="enscript-comment">;; the arrow's line.
</span>	      (<span class="enscript-keyword">when</span> (featurep 'hl-line)
		(<span class="enscript-keyword">cond</span>
		 (global-hl-line-mode
		  (global-hl-line-highlight))
		 ((<span class="enscript-keyword">and</span> hl-line-mode hl-line-sticky-flag)
		  (hl-line-highlight)))))
	    (<span class="enscript-keyword">cond</span> ((<span class="enscript-keyword">or</span> (&lt; pos (point-min)) (&gt; pos (point-max)))
		   (widen)
		   (goto-char pos))))
	  (<span class="enscript-keyword">when</span> window
	    (set-window-point window gud-overlay-arrow-position)
	    (<span class="enscript-keyword">if</span> (memq gud-minor-mode '(gdbmi gdba))
		(setq gdb-source-window window)))))))

<span class="enscript-comment">;; The gud-call function must do the right thing whether its invoking
</span><span class="enscript-comment">;; keystroke is from the GUD buffer itself (via major-mode binding)
</span><span class="enscript-comment">;; or a C buffer.  In the former case, we want to supply data from
</span><span class="enscript-comment">;; gud-last-frame.  Here's how we do it:
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-format-command</span> (str arg)
  (<span class="enscript-keyword">let</span> ((insource (not (eq (current-buffer) gud-comint-buffer)))
	(frame (<span class="enscript-keyword">or</span> gud-last-frame gud-last-last-frame))
	result)
    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> str
		(<span class="enscript-keyword">let</span> ((case-fold-search nil))
		  (string-match <span class="enscript-string">&quot;\\([^%]*\\)%\\([abdefFlpc]\\)&quot;</span> str)))
      (<span class="enscript-keyword">let</span> ((key (string-to-char (match-string 2 str)))
	    subst)
	(<span class="enscript-keyword">cond</span>
	 ((eq key ?f)
	  (setq subst (file-name-nondirectory (<span class="enscript-keyword">if</span> insource
						  (buffer-file-name)
						(car frame)))))
	 ((eq key ?F)
	  (setq subst (file-name-sans-extension
		       (file-name-nondirectory (<span class="enscript-keyword">if</span> insource
						   (buffer-file-name)
						 (car frame))))))
	 ((eq key ?d)
	  (setq subst (file-name-directory (<span class="enscript-keyword">if</span> insource
					       (buffer-file-name)
					     (car frame)))))
	 ((eq key ?l)
	  (setq subst (int-to-string
		       (<span class="enscript-keyword">if</span> insource
			   (<span class="enscript-keyword">save-restriction</span>
			     (widen)
			     (+ (count-lines (point-min) (point))
				(<span class="enscript-keyword">if</span> (bolp) 1 0)))
			 (cdr frame)))))
	 ((eq key ?e)
	  (setq subst (gud-find-expr)))
	 ((eq key ?a)
	  (setq subst (gud-read-address)))
	 ((eq key ?b)
	  (setq subst gud-breakpoint-id))
	 ((eq key ?c)
	  (setq subst
                (gud-find-class
                 (<span class="enscript-keyword">if</span> insource
                      (buffer-file-name)
                    (car frame))
                 (<span class="enscript-keyword">if</span> insource
                      (<span class="enscript-keyword">save-restriction</span>
                        (widen)
                        (+ (count-lines (point-min) (point))
                           (<span class="enscript-keyword">if</span> (bolp) 1 0)))
                    (cdr frame)))))
	 ((eq key ?p)
	  (setq subst (<span class="enscript-keyword">if</span> arg (int-to-string arg)))))
	(setq result (concat result (match-string 1 str) subst)))
      (setq str (substring str (match-end 2))))
    <span class="enscript-comment">;; There might be text left in STR when the loop ends.
</span>    (concat result str)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-read-address</span> ()
  <span class="enscript-string">&quot;Return a string containing the core-address found in the buffer at point.&quot;</span>
  (<span class="enscript-keyword">save-match-data</span>
    (<span class="enscript-keyword">save-excursion</span>
      (<span class="enscript-keyword">let</span> ((pt (point)) found begin)
	(setq found (<span class="enscript-keyword">if</span> (search-backward <span class="enscript-string">&quot;0x&quot;</span> (- pt 7) t) (point)))
	(<span class="enscript-keyword">cond</span>
	 (found (forward-char 2)
		(buffer-substring found
				  (<span class="enscript-keyword">progn</span> (re-search-forward <span class="enscript-string">&quot;[^0-9a-f]&quot;</span>)
					 (forward-char -1)
					 (point))))
	 (t (setq begin (<span class="enscript-keyword">progn</span> (re-search-backward <span class="enscript-string">&quot;[^0-9]&quot;</span>)
			       (forward-char 1)
			       (point)))
	    (forward-char 1)
	    (re-search-forward <span class="enscript-string">&quot;[^0-9]&quot;</span>)
	    (forward-char -1)
	    (buffer-substring begin (point))))))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-call</span> (fmt &amp;optional arg)
  (<span class="enscript-keyword">let</span> ((msg (gud-format-command fmt arg)))
    (message <span class="enscript-string">&quot;Command: %s&quot;</span> msg)
    (sit-for 0)
    (gud-basic-call msg)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-basic-call</span> (command)
  <span class="enscript-string">&quot;Invoke the debugger COMMAND displaying source in other window.&quot;</span>
  (interactive)
  (gud-set-buffer)
  (<span class="enscript-keyword">let</span> ((proc (get-buffer-process gud-comint-buffer)))
    (<span class="enscript-keyword">or</span> proc (error <span class="enscript-string">&quot;Current buffer has no process&quot;</span>))
    <span class="enscript-comment">;; Arrange for the current prompt to get deleted.
</span>    (<span class="enscript-keyword">save-excursion</span>
      (set-buffer gud-comint-buffer)
      (<span class="enscript-keyword">save-restriction</span>
	(widen)
	(<span class="enscript-keyword">if</span> (marker-position gud-delete-prompt-marker)
	    <span class="enscript-comment">;; We get here when printing an expression.
</span>	    (goto-char gud-delete-prompt-marker)
	  (goto-char (process-mark proc))
	  (forward-line 0))
	(<span class="enscript-keyword">if</span> (looking-at comint-prompt-regexp)
	    (set-marker gud-delete-prompt-marker (point)))
	(<span class="enscript-keyword">if</span> (memq gud-minor-mode '(gdbmi gdba))
	    (apply comint-input-sender (list proc command))
	  (process-send-string proc (concat command <span class="enscript-string">&quot;\n&quot;</span>)))))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-refresh</span> (&amp;optional arg)
  <span class="enscript-string">&quot;Fix up a possibly garbled display, and redraw the arrow.&quot;</span>
  (interactive <span class="enscript-string">&quot;P&quot;</span>)
  (<span class="enscript-keyword">or</span> gud-last-frame (setq gud-last-frame gud-last-last-frame))
  (gud-display-frame)
  (recenter arg))

<span class="enscript-comment">;; Code for parsing expressions out of C or Fortran code.  The single entry
</span><span class="enscript-comment">;; point is gud-find-expr, which tries to return an lvalue expression from
</span><span class="enscript-comment">;; around point.
</span>
(defvar gud-find-expr-function 'gud-find-c-expr)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-find-expr</span> (&amp;rest args)
  (<span class="enscript-keyword">let</span> ((expr (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> transient-mark-mode mark-active)
		  (buffer-substring (region-beginning) (region-end))
		(apply gud-find-expr-function args))))
    (<span class="enscript-keyword">save-match-data</span>
      (<span class="enscript-keyword">if</span> (string-match <span class="enscript-string">&quot;\n&quot;</span> expr)
	  (error <span class="enscript-string">&quot;Expression must not include a newline&quot;</span>))
      (with-current-buffer gud-comint-buffer
	(<span class="enscript-keyword">save-excursion</span>
	  (goto-char (process-mark (get-buffer-process gud-comint-buffer)))
	  (forward-line 0)
	  (<span class="enscript-keyword">when</span> (looking-at comint-prompt-regexp)
	    (set-marker gud-delete-prompt-marker (point))
	    (set-marker-insertion-type gud-delete-prompt-marker t))
	  (<span class="enscript-keyword">unless</span> (eq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		      'jdb)
	      (insert (concat  expr <span class="enscript-string">&quot; = &quot;</span>))))))
    expr))

<span class="enscript-comment">;; The next eight functions are hacked from gdbsrc.el by
</span><span class="enscript-comment">;; Debby Ayers &lt;<a href="mailto:ayers@asc.slb.com">ayers@asc.slb.com</a>&gt;,
</span><span class="enscript-comment">;; Rich Schaefer &lt;<a href="mailto:schaefer@asc.slb.com">schaefer@asc.slb.com</a>&gt; Schlumberger, Austin, Tx.
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-find-c-expr</span> ()
  <span class="enscript-string">&quot;Returns the expr that surrounds point.&quot;</span>
  (interactive)
  (<span class="enscript-keyword">save-excursion</span>
    (<span class="enscript-keyword">let</span> ((p (point))
	  (expr (gud-innermost-expr))
	  (test-expr (gud-prev-expr)))
      (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> test-expr (gud-expr-compound test-expr expr))
	(<span class="enscript-keyword">let</span> ((prev-expr expr))
	  (setq expr (cons (car test-expr) (cdr expr)))
	  (goto-char (car expr))
	  (setq test-expr (gud-prev-expr))
	  <span class="enscript-comment">;; If we just pasted on the condition of an if or while,
</span>	  <span class="enscript-comment">;; throw it away again.
</span>	  (<span class="enscript-keyword">if</span> (member (buffer-substring (car test-expr) (cdr test-expr))
		      '(<span class="enscript-string">&quot;if&quot;</span> <span class="enscript-string">&quot;while&quot;</span> <span class="enscript-string">&quot;for&quot;</span>))
	      (setq test-expr nil
		    expr prev-expr))))
      (goto-char p)
      (setq test-expr (gud-next-expr))
      (<span class="enscript-keyword">while</span> (gud-expr-compound expr test-expr)
	(setq expr (cons (car expr) (cdr test-expr)))
	(setq test-expr (gud-next-expr)))
      (buffer-substring (car expr) (cdr expr)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-innermost-expr</span> ()
  <span class="enscript-string">&quot;Returns the smallest expr that point is in; move point to beginning of it.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr.&quot;</span>
  (<span class="enscript-keyword">let</span> ((p (point)) begin end)
    (gud-backward-sexp)
    (setq begin (point))
    (gud-forward-sexp)
    (setq end (point))
    (<span class="enscript-keyword">if</span> (&gt;= p end)
	(<span class="enscript-keyword">progn</span>
	 (setq begin p)
	 (goto-char p)
	 (gud-forward-sexp)
	 (setq end (point)))
      )
    (goto-char begin)
    (cons begin end)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-backward-sexp</span> ()
  <span class="enscript-string">&quot;Version of `backward-sexp' that catches errors.&quot;</span>
  (<span class="enscript-keyword">condition-case</span> nil
      (backward-sexp)
    (error t)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-forward-sexp</span> ()
  <span class="enscript-string">&quot;Version of `forward-sexp' that catches errors.&quot;</span>
  (<span class="enscript-keyword">condition-case</span> nil
     (forward-sexp)
    (error t)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-prev-expr</span> ()
  <span class="enscript-string">&quot;Returns the previous expr, point is set to beginning of that expr.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr&quot;</span>
  (<span class="enscript-keyword">let</span> ((begin) (end))
    (gud-backward-sexp)
    (setq begin (point))
    (gud-forward-sexp)
    (setq end (point))
    (goto-char begin)
    (cons begin end)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-next-expr</span> ()
  <span class="enscript-string">&quot;Returns the following expr, point is set to beginning of that expr.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr.&quot;</span>
  (<span class="enscript-keyword">let</span> ((begin) (end))
    (gud-forward-sexp)
    (gud-forward-sexp)
    (setq end (point))
    (gud-backward-sexp)
    (setq begin (point))
    (cons begin end)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-expr-compound-sep</span> (span-start span-end)
  <span class="enscript-string">&quot;Scan from SPAN-START to SPAN-END for punctuation characters.
If `-&gt;' is found, return `?.'.  If `.' is found, return `?.'.
If any other punctuation is found, return `??'.
If no punctuation is found, return `? '.&quot;</span>
  (<span class="enscript-keyword">let</span> ((result ?\s)
	(syntax))
    (<span class="enscript-keyword">while</span> (&lt; span-start span-end)
      (setq syntax (char-syntax (char-after span-start)))
      (<span class="enscript-keyword">cond</span>
       ((= syntax ?\s) t)
       ((= syntax ?.) (setq syntax (char-after span-start))
	(<span class="enscript-keyword">cond</span>
	 ((= syntax ?.) (setq result ?.))
	 ((<span class="enscript-keyword">and</span> (= syntax ?-) (= (char-after (+ span-start 1)) ?&gt;))
	  (setq result ?.)
	  (setq span-start (+ span-start 1)))
	 (t (setq span-start span-end)
	    (setq result ??)))))
      (setq span-start (+ span-start 1)))
    result))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-expr-compound</span> (first second)
  <span class="enscript-string">&quot;Non-nil if concatenating FIRST and SECOND makes a single C expression.
The two exprs are represented as a cons cells, where the car
specifies the point in the current buffer that marks the beginning of the
expr and the cdr specifies the character after the end of the expr.
Link exprs of the form:
      Expr -&gt; Expr
      Expr . Expr
      Expr (Expr)
      Expr [Expr]
      (Expr) Expr
      [Expr] Expr&quot;</span>
  (<span class="enscript-keyword">let</span> ((span-start (cdr first))
	(span-end (car second))
	(syntax))
    (setq syntax (gud-expr-compound-sep span-start span-end))
    (<span class="enscript-keyword">cond</span>
     ((= (car first) (car second)) nil)
     ((= (cdr first) (cdr second)) nil)
     ((= syntax ?.) t)
     ((= syntax ?\s)
      (setq span-start (char-after (- span-start 1)))
      (setq span-end (char-after span-end))
      (<span class="enscript-keyword">cond</span>
       ((= span-start ?)) t)
      ((= span-start ?]) t)
     ((= span-end ?() t)
      ((= span-end ?[) t)
       (t nil)))
     (t nil))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-find-class</span> (f line)
  <span class="enscript-string">&quot;Find fully qualified class in file F at line LINE.
This function uses the `gud-jdb-classpath' (and optional
`gud-jdb-sourcepath') list(s) to derive a file
pathname relative to its classpath directory.  The values in
`gud-jdb-classpath' are assumed to have been converted to absolute
pathname standards using file-truename.
If F is visited by a buffer and its mode is CC-mode(Java),
syntactic information of LINE is used to find the enclosing (nested)
class string which is appended to the top level
class of the file (using s to separate nested class ids).&quot;</span>
  <span class="enscript-comment">;; Convert f to a standard representation and remove suffix
</span>  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> gud-jdb-use-classpath (<span class="enscript-keyword">or</span> gud-jdb-classpath gud-jdb-sourcepath))
      (<span class="enscript-keyword">save-match-data</span>
        (<span class="enscript-keyword">let</span> ((cplist (append gud-jdb-sourcepath gud-jdb-classpath))
              (fbuffer (get-file-buffer f))
              syntax-symbol syntax-point class-found)
          (setq f (file-name-sans-extension (file-truename f)))
          <span class="enscript-comment">;; Syntax-symbol returns the symbol of the *first* element
</span>          <span class="enscript-comment">;; in the syntactical analysis result list, syntax-point
</span>          <span class="enscript-comment">;; returns the buffer position of same
</span>          (fset 'syntax-symbol (<span class="enscript-keyword">lambda</span> (x) (c-langelem-sym (car x))))
          (fset 'syntax-point (<span class="enscript-keyword">lambda</span> (x) (c-langelem-pos (car x))))
          <span class="enscript-comment">;; Search through classpath list for an entry that is
</span>          <span class="enscript-comment">;; contained in f
</span>          (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> cplist (not class-found))
            (<span class="enscript-keyword">if</span> (string-match (car cplist) f)
                (setq class-found
		      (mapconcat 'identity
                                 (split-string
                                   (substring f (+ (match-end 0) 1))
                                  <span class="enscript-string">&quot;/&quot;</span>) <span class="enscript-string">&quot;.&quot;</span>)))
            (setq cplist (cdr cplist)))
          <span class="enscript-comment">;; if f is visited by a java(cc-mode) buffer, walk up the
</span>          <span class="enscript-comment">;; syntactic information chain and collect any 'inclass
</span>          <span class="enscript-comment">;; symbols until 'topmost-intro is reached to find out if
</span>          <span class="enscript-comment">;; point is within a nested class
</span>          (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> fbuffer (equal (symbol-file 'java-mode) <span class="enscript-string">&quot;cc-mode&quot;</span>))
              (<span class="enscript-keyword">save-excursion</span>
                (set-buffer fbuffer)
                (<span class="enscript-keyword">let</span> ((nclass) (syntax))
                  <span class="enscript-comment">;; While the c-syntactic information does not start
</span>                  <span class="enscript-comment">;; with the 'topmost-intro symbol, there may be
</span>                  <span class="enscript-comment">;; nested classes...
</span>                  (<span class="enscript-keyword">while</span> (not (eq 'topmost-intro
                                  (syntax-symbol (c-guess-basic-syntax))))
                    <span class="enscript-comment">;; Check if the current position c-syntactic
</span>                    <span class="enscript-comment">;; analysis has 'inclass
</span>                    (setq syntax (c-guess-basic-syntax))
                    (<span class="enscript-keyword">while</span>
                        (<span class="enscript-keyword">and</span> (not (eq 'inclass (syntax-symbol syntax)))
                             (cdr syntax))
                      (setq syntax (cdr syntax)))
                    (<span class="enscript-keyword">if</span> (eq 'inclass (syntax-symbol syntax))
                        (<span class="enscript-keyword">progn</span>
                          (goto-char (syntax-point syntax))
                          <span class="enscript-comment">;; Now we're at the beginning of a class
</span>                          <span class="enscript-comment">;; definition.  Find class name
</span>                          (looking-at
                           <span class="enscript-string">&quot;[A-Za-z0-9 \t\n]*?class[ \t\n]+\\([^ \t\n]+\\)&quot;</span>)
                          (setq nclass
                                (append (list (match-string-no-properties 1))
                                        nclass)))
                      (setq syntax (c-guess-basic-syntax))
                      (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> (not (syntax-point syntax)) (cdr syntax))
                        (setq syntax (cdr syntax)))
                      (goto-char (syntax-point syntax))
                      ))
                  (string-match (concat (car nclass) <span class="enscript-string">&quot;$&quot;</span>) class-found)
                  (setq class-found
                        (replace-match (mapconcat 'identity nclass <span class="enscript-string">&quot;$&quot;</span>)
                                       t t class-found)))))
          (<span class="enscript-keyword">if</span> (not class-found)
              (message <span class="enscript-string">&quot;gud-find-class: class for file %s not found!&quot;</span> f))
          class-found))
    <span class="enscript-comment">;; Not using classpath - try class/source association list
</span>    (<span class="enscript-keyword">let</span> ((class-found (rassoc f gud-jdb-class-source-alist)))
      (<span class="enscript-keyword">if</span> class-found
	  (car class-found)
	(message <span class="enscript-string">&quot;gud-find-class: class for file %s not found in gud-jdb-class-source-alist!&quot;</span> f)
	nil))))


<span class="enscript-comment">;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
</span><span class="enscript-comment">;;; GDB script mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
</span><span class="enscript-comment">;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
</span>
(defvar gdb-script-mode-syntax-table
  (<span class="enscript-keyword">let</span> ((st (make-syntax-table)))
    (modify-syntax-entry ?' <span class="enscript-string">&quot;\&quot;&quot;</span> st)
    (modify-syntax-entry ?# <span class="enscript-string">&quot;&lt;&quot;</span> st)
    (modify-syntax-entry ?\n <span class="enscript-string">&quot;&gt;&quot;</span> st)
    st))

(defvar gdb-script-font-lock-keywords
  '((<span class="enscript-string">&quot;^define\\s-+\\(\\(\\w\\|\\s_\\)+\\)&quot;</span> (1 font-lock-function-name-face))
    (<span class="enscript-string">&quot;\\$\\(\\w+\\)&quot;</span> (1 font-lock-variable-name-face))
    (<span class="enscript-string">&quot;^\\s-*\\(\\w\\(\\w\\|\\s_\\)*\\)&quot;</span> (1 font-lock-keyword-face))))

(defvar gdb-script-font-lock-syntactic-keywords
  '((<span class="enscript-string">&quot;^document\\s-.*\\(\n\\)&quot;</span> (1 <span class="enscript-string">&quot;&lt; b&quot;</span>))
    (<span class="enscript-string">&quot;^end\\&gt;&quot;</span>
     (0 (<span class="enscript-keyword">unless</span> (eq (match-beginning 0) (point-min))
          <span class="enscript-comment">;; We change the \n in front, which is more difficult, but results
</span>          <span class="enscript-comment">;; in better highlighting.  If the doc is empty, the single \n is
</span>          <span class="enscript-comment">;; both the beginning and the end of the docstring, which can't be
</span>          <span class="enscript-comment">;; expressed in syntax-tables.  Instead, we place the &quot;&gt; b&quot; after
</span>          <span class="enscript-comment">;; placing the &quot;&lt; b&quot;, so the start marker is overwritten by the
</span>          <span class="enscript-comment">;; termination marker and in the end Emacs simply considers that
</span>          <span class="enscript-comment">;; there's no docstring at all, which is fine.
</span>          (put-text-property (1- (match-beginning 0)) (match-beginning 0)
                             'syntax-table (<span class="enscript-keyword">eval-when-compile</span>
                                             (string-to-syntax <span class="enscript-string">&quot;&gt; b&quot;</span>)))
          <span class="enscript-comment">;; Make sure that rehighlighting the previous line won't erase our
</span>          <span class="enscript-comment">;; syntax-table property.
</span>          (put-text-property (1- (match-beginning 0)) (match-end 0)
                             'font-lock-multiline t)
          nil)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-font-lock-syntactic-face</span> (state)
  (<span class="enscript-keyword">cond</span>
   ((nth 3 state) font-lock-string-face)
   ((nth 7 state) font-lock-doc-face)
   (t font-lock-comment-face)))

(defvar gdb-script-basic-indent 2)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-skip-to-head</span> ()
  <span class="enscript-string">&quot;We're just in front of an `end' and we need to go to its head.&quot;</span>
  (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> (re-search-backward <span class="enscript-string">&quot;^\\s-*\\(\\(end\\)\\|define\\|document\\|if\\|while\\|commands\\)\\&gt;&quot;</span> nil 'move)
	      (match-end 2))
    (gdb-script-skip-to-head)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-calculate-indentation</span> ()
  (<span class="enscript-keyword">cond</span>
   ((looking-at <span class="enscript-string">&quot;end\\&gt;&quot;</span>)
    (gdb-script-skip-to-head)
    (current-indentation))
   ((looking-at <span class="enscript-string">&quot;else\\&gt;&quot;</span>)
    (<span class="enscript-keyword">while</span> (<span class="enscript-keyword">and</span> (re-search-backward <span class="enscript-string">&quot;^\\s-*\\(if\\|\\(end\\)\\)\\&gt;&quot;</span> nil 'move)
		(match-end 2))
      (gdb-script-skip-to-head))
    (current-indentation))
   (t
    (forward-comment (- (point-max)))
    (forward-line 0)
    (skip-chars-forward <span class="enscript-string">&quot; \t&quot;</span>)
    (+ (current-indentation)
       (<span class="enscript-keyword">if</span> (looking-at <span class="enscript-string">&quot;\\(if\\|while\\|define\\|else\\|commands\\)\\&gt;&quot;</span>)
	   gdb-script-basic-indent 0)))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-indent-line</span> ()
  <span class="enscript-string">&quot;Indent current line of GDB script.&quot;</span>
  (interactive)
  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (eq (get-text-property (point) 'face) font-lock-doc-face)
	   (<span class="enscript-keyword">save-excursion</span>
	     (forward-line 0)
	     (skip-chars-forward <span class="enscript-string">&quot; \t&quot;</span>)
	     (not (looking-at <span class="enscript-string">&quot;end\\&gt;&quot;</span>))))
      'noindent
    (<span class="enscript-keyword">let</span>* ((savep (point))
	   (indent (<span class="enscript-keyword">condition-case</span> nil
		       (<span class="enscript-keyword">save-excursion</span>
			 (forward-line 0)
			 (skip-chars-forward <span class="enscript-string">&quot; \t&quot;</span>)
			 (<span class="enscript-keyword">if</span> (&gt;= (point) savep) (setq savep nil))
			 (max (gdb-script-calculate-indentation) 0))
		     (error 0))))
      (<span class="enscript-keyword">if</span> savep
	  (<span class="enscript-keyword">save-excursion</span> (indent-line-to indent))
	(indent-line-to indent)))))

<span class="enscript-comment">;; Derived from cfengine.el.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-beginning-of-defun</span> ()
  <span class="enscript-string">&quot;`beginning-of-defun' function for Gdb script mode.
Treats actions as defuns.&quot;</span>
  (<span class="enscript-keyword">unless</span> (&lt;= (current-column) (current-indentation))
    (end-of-line))
  (<span class="enscript-keyword">if</span> (re-search-backward <span class="enscript-string">&quot;^define \\|^document &quot;</span> nil t)
      (beginning-of-line)
    (goto-char (point-min)))
  t)

<span class="enscript-comment">;; Derived from cfengine.el.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gdb-script-end-of-defun</span> ()
  <span class="enscript-string">&quot;`end-of-defun' function for Gdb script mode.
Treats actions as defuns.&quot;</span>
  (end-of-line)
  (<span class="enscript-keyword">if</span> (re-search-forward <span class="enscript-string">&quot;^end&quot;</span> nil t)
      (beginning-of-line)
    (goto-char (point-max)))
  t)

<span class="enscript-comment">;; Besides .gdbinit, gdb documents other names to be usable for init
</span><span class="enscript-comment">;; files, cross-debuggers can use something like
</span><span class="enscript-comment">;; .PROCESSORNAME-gdbinit so that the host and target gdbinit files
</span><span class="enscript-comment">;; don't interfere with each other.
</span><span class="enscript-comment">;;;###autoload
</span>(add-to-list 'auto-mode-alist '(<span class="enscript-string">&quot;/\\.[a-z0-9-]*gdbinit&quot;</span> . gdb-script-mode))

<span class="enscript-comment">;;;###autoload
</span>(define-derived-mode gdb-script-mode nil <span class="enscript-string">&quot;GDB-Script&quot;</span>
  <span class="enscript-string">&quot;Major mode for editing GDB scripts.&quot;</span>
  (set (make-local-variable 'comment-start) <span class="enscript-string">&quot;#&quot;</span>)
  (set (make-local-variable 'comment-start-skip) <span class="enscript-string">&quot;#+\\s-*&quot;</span>)
  (set (make-local-variable 'outline-regexp) <span class="enscript-string">&quot;[ \t]&quot;</span>)
  (set (make-local-variable 'imenu-generic-expression)
       '((nil <span class="enscript-string">&quot;^define[ \t]+\\(\\w+\\)&quot;</span> 1)))
  (set (make-local-variable 'indent-line-function) 'gdb-script-indent-line)
  (set (make-local-variable 'beginning-of-defun-function)
       #'gdb-script-beginning-of-defun)
  (set (make-local-variable 'end-of-defun-function)
       #'gdb-script-end-of-defun)
  (set (make-local-variable 'font-lock-defaults)
       '(gdb-script-font-lock-keywords nil nil ((?_ . <span class="enscript-string">&quot;w&quot;</span>)) nil
	 (font-lock-syntactic-keywords
	  . gdb-script-font-lock-syntactic-keywords)
	 (font-lock-syntactic-face-function
	  . gdb-script-font-lock-syntactic-face))))


<span class="enscript-comment">;;; tooltips for GUD
</span>
<span class="enscript-comment">;;; Customizable settings
</span>
(define-minor-mode gud-tooltip-mode
  <span class="enscript-string">&quot;Toggle the display of GUD tooltips.&quot;</span>
  <span class="enscript-reference">:global</span> t
  <span class="enscript-reference">:group</span> 'gud
  <span class="enscript-reference">:group</span> 'tooltip
  (require 'tooltip)
  (<span class="enscript-keyword">if</span> gud-tooltip-mode
      (<span class="enscript-keyword">progn</span>
	(add-hook 'change-major-mode-hook 'gud-tooltip-change-major-mode)
	(add-hook 'pre-command-hook 'tooltip-hide)
	(add-hook 'tooltip-hook 'gud-tooltip-tips)
	(define-key global-map [mouse-movement] 'gud-tooltip-mouse-motion))
    (<span class="enscript-keyword">unless</span> tooltip-mode (remove-hook 'pre-command-hook 'tooltip-hide)
    (remove-hook 'change-major-mode-hook 'gud-tooltip-change-major-mode)
    (remove-hook 'tooltip-hook 'gud-tooltip-tips)
    (define-key global-map [mouse-movement] 'ignore)))
  (gud-tooltip-activate-mouse-motions-<span class="enscript-keyword">if</span>-enabled)
  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> gud-comint-buffer
	   (buffer-name gud-comint-buffer)<span class="enscript-comment">; gud-comint-buffer might be killed
</span>	   (memq (buffer-local-value 'gud-minor-mode gud-comint-buffer)
		 '(gdbmi gdba)))
      (<span class="enscript-keyword">if</span> gud-tooltip-mode
	  (<span class="enscript-keyword">progn</span>
	    (dolist (buffer (buffer-list))
	      (<span class="enscript-keyword">unless</span> (eq buffer gud-comint-buffer)
		(with-current-buffer buffer
		  (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> (memq gud-minor-mode '(gdbmi gdba))
			     (not (string-match <span class="enscript-string">&quot;\\`\\*.+\\*\\'&quot;</span>
						(buffer-name))))
		    (make-local-variable 'gdb-define-alist)
		    (gdb-create-define-alist)
		    (add-hook 'after-save-hook
			      'gdb-create-define-alist nil t))))))
	(kill-local-variable 'gdb-define-alist)
	(remove-hook 'after-save-hook 'gdb-create-define-alist t))))

(defcustom gud-tooltip-modes '(gud-mode c-mode c++-mode fortran-mode
					python-mode)
  <span class="enscript-string">&quot;List of modes for which to enable GUD tooltips.&quot;</span>
  <span class="enscript-reference">:type</span> 'sexp
  <span class="enscript-reference">:group</span> 'gud
  <span class="enscript-reference">:group</span> 'tooltip)

(defcustom gud-tooltip-display
  '((eq (tooltip-event-buffer gud-tooltip-event)
	(marker-buffer gud-overlay-arrow-position)))
  <span class="enscript-string">&quot;List of forms determining where GUD tooltips are displayed.

Forms in the list are combined with AND.  The default is to display
only tooltips in the buffer containing the overlay arrow.&quot;</span>
  <span class="enscript-reference">:type</span> 'sexp
  <span class="enscript-reference">:group</span> 'gud
  <span class="enscript-reference">:group</span> 'tooltip)

(defcustom gud-tooltip-echo-area nil
  <span class="enscript-string">&quot;Use the echo area instead of frames for GUD tooltips.&quot;</span>
  <span class="enscript-reference">:type</span> 'boolean
  <span class="enscript-reference">:group</span> 'gud
  <span class="enscript-reference">:group</span> 'tooltip)

(define-obsolete-variable-alias 'tooltip-gud-modes
                                'gud-tooltip-modes <span class="enscript-string">&quot;22.1&quot;</span>)
(define-obsolete-variable-alias 'tooltip-gud-display
                                'gud-tooltip-display <span class="enscript-string">&quot;22.1&quot;</span>)

<span class="enscript-comment">;;; Reacting on mouse movements
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-change-major-mode</span> ()
  <span class="enscript-string">&quot;Function added to `change-major-mode-hook' when tooltip mode is on.&quot;</span>
  (add-hook 'post-command-hook 'gud-tooltip-activate-mouse-motions-<span class="enscript-keyword">if</span>-enabled))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-activate-mouse-motions-if-enabled</span> ()
  <span class="enscript-string">&quot;Reconsider for all buffers whether mouse motion events are desired.&quot;</span>
  (remove-hook 'post-command-hook
	       'gud-tooltip-activate-mouse-motions-<span class="enscript-keyword">if</span>-enabled)
  (dolist (buffer (buffer-list))
    (<span class="enscript-keyword">save-excursion</span>
      (set-buffer buffer)
      (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> gud-tooltip-mode
	       (memq major-mode gud-tooltip-modes))
	  (gud-tooltip-activate-mouse-motions t)
	(gud-tooltip-activate-mouse-motions nil)))))

(defvar gud-tooltip-mouse-motions-active nil
  <span class="enscript-string">&quot;Locally t in a buffer if tooltip processing of mouse motion is enabled.&quot;</span>)

<span class="enscript-comment">;; We don't set track-mouse globally because this is a big redisplay
</span><span class="enscript-comment">;; problem in buffers having a pre-command-hook or such installed,
</span><span class="enscript-comment">;; which does a set-buffer, like the summary buffer of Gnus.  Calling
</span><span class="enscript-comment">;; set-buffer prevents redisplay optimizations, so every mouse motion
</span><span class="enscript-comment">;; would be accompanied by a full redisplay.
</span>
(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-activate-mouse-motions</span> (activatep)
  <span class="enscript-string">&quot;Activate/deactivate mouse motion events for the current buffer.
ACTIVATEP non-nil means activate mouse motion events.&quot;</span>
  (<span class="enscript-keyword">if</span> activatep
      (<span class="enscript-keyword">progn</span>
	(make-local-variable 'gud-tooltip-mouse-motions-active)
	(setq gud-tooltip-mouse-motions-active t)
	(make-local-variable '<span class="enscript-keyword">track-mouse</span>)
	(setq <span class="enscript-keyword">track-mouse</span> t))
    (<span class="enscript-keyword">when</span> gud-tooltip-mouse-motions-active
      (kill-local-variable 'gud-tooltip-mouse-motions-active)
      (kill-local-variable '<span class="enscript-keyword">track-mouse</span>))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-mouse-motion</span> (event)
  <span class="enscript-string">&quot;Command handler for mouse movement events in `global-map'.&quot;</span>
  (interactive <span class="enscript-string">&quot;e&quot;</span>)
  (tooltip-hide)
  (<span class="enscript-keyword">when</span> (car (mouse-pixel-position))
    (setq tooltip-last-mouse-motion-event (copy-sequence event))
    (tooltip-start-delayed-tip)))

<span class="enscript-comment">;;; Tips for `gud'
</span>
(defvar gud-tooltip-original-filter nil
  <span class="enscript-string">&quot;Process filter to restore after GUD output has been received.&quot;</span>)

(defvar gud-tooltip-dereference nil
  <span class="enscript-string">&quot;Non-nil means print expressions with a `*' in front of them.
For C this would dereference a pointer expression.&quot;</span>)

(defvar gud-tooltip-event nil
  <span class="enscript-string">&quot;The mouse movement event that led to a tooltip display.
This event can be examined by forms in `gud-tooltip-display'.&quot;</span>)

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-dereference</span> (&amp;optional arg)
  <span class="enscript-string">&quot;Toggle whether tooltips should show `* expr' or `expr'.
With arg, dereference expr if ARG is positive, otherwise do not derereference.&quot;</span>
 (interactive <span class="enscript-string">&quot;P&quot;</span>)
  (setq gud-tooltip-dereference
	(<span class="enscript-keyword">if</span> (null arg)
	    (not gud-tooltip-dereference)
	  (&gt; (prefix-numeric-value arg) 0)))
  (message <span class="enscript-string">&quot;Dereferencing is now %s.&quot;</span>
	   (<span class="enscript-keyword">if</span> gud-tooltip-dereference <span class="enscript-string">&quot;on&quot;</span> <span class="enscript-string">&quot;off&quot;</span>)))

(define-obsolete-function-alias 'tooltip-gud-toggle-dereference
                                'gud-tooltip-dereference <span class="enscript-string">&quot;22.1&quot;</span>)

<span class="enscript-comment">; This will only display data that comes in one chunk.
</span><span class="enscript-comment">; Larger arrays (say 400 elements) are displayed in
</span><span class="enscript-comment">; the tooltip incompletely and spill over into the gud buffer.
</span><span class="enscript-comment">; Switching the process-filter creates timing problems and
</span><span class="enscript-comment">; it may be difficult to do better. Using annotations as in
</span><span class="enscript-comment">; gdb-ui.el gets round this problem.
</span>(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-process-output</span> (process output)
  <span class="enscript-string">&quot;Process debugger output and show it in a tooltip window.&quot;</span>
  (set-process-filter process gud-tooltip-original-filter)
  (tooltip-show (tooltip-strip-prompt process output)
		(<span class="enscript-keyword">or</span> gud-tooltip-echo-area tooltip-use-echo-area)))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-print-command</span> (expr)
  <span class="enscript-string">&quot;Return a suitable command to print the expression EXPR.&quot;</span>
  (case gud-minor-mode
        <span class="enscript-comment">; '-o' to print the objc object description if available
</span>        (lldb (concat <span class="enscript-string">&quot;expression -o -- &quot;</span> expr))
	(gdba (concat <span class="enscript-string">&quot;server print &quot;</span> expr))
	((dbx gdbmi) (concat <span class="enscript-string">&quot;print &quot;</span> expr))
	((xdb pdb) (concat <span class="enscript-string">&quot;p &quot;</span> expr))
	(sdb (concat expr <span class="enscript-string">&quot;/&quot;</span>))))

(<span class="enscript-keyword">defun</span> <span class="enscript-function-name">gud-tooltip-tips</span> (event)
  <span class="enscript-string">&quot;Show tip for identifier or selection under the mouse.
The mouse must either point at an identifier or inside a selected
region for the tip window to be shown.  If `gud-tooltip-dereference' is t,
add a `*' in front of the printed expression.  In the case of a C program
controlled by GDB, show the associated #define directives when program is
not executing.

This function must return nil if it doesn't handle EVENT.&quot;</span>
  (<span class="enscript-keyword">let</span> (process)
    (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> (eventp event)
	       gud-tooltip-mode
	       gud-comint-buffer
	       (buffer-name gud-comint-buffer)<span class="enscript-comment">; might be killed
</span>	       (setq process (get-buffer-process gud-comint-buffer))
	       (posn-point (event-end event))
	       (<span class="enscript-keyword">or</span> (<span class="enscript-keyword">and</span> (eq gud-minor-mode 'gdba) (not gdb-active-process))
		   (<span class="enscript-keyword">progn</span> (setq gud-tooltip-event event)
			  (eval (cons '<span class="enscript-keyword">and</span> gud-tooltip-display)))))
      (<span class="enscript-keyword">let</span> ((expr (tooltip-expr-to-print event)))
	(<span class="enscript-keyword">when</span> expr
	  (<span class="enscript-keyword">if</span> (<span class="enscript-keyword">and</span> (eq gud-minor-mode 'gdba)
		   (not gdb-active-process))
	      (<span class="enscript-keyword">progn</span>
		(with-current-buffer (tooltip-event-buffer event)
		  (<span class="enscript-keyword">let</span> ((define-elt (assoc expr gdb-define-alist)))
		    (<span class="enscript-keyword">unless</span> (null define-elt)
		      (tooltip-show
		       (cdr define-elt)
		       (<span class="enscript-keyword">or</span> gud-tooltip-echo-area tooltip-use-echo-area))
		      expr))))
	    (<span class="enscript-keyword">when</span> gud-tooltip-dereference
	      (setq expr (concat <span class="enscript-string">&quot;*&quot;</span> expr)))
	    (<span class="enscript-keyword">let</span> ((cmd (gud-tooltip-print-command expr)))
	      (<span class="enscript-keyword">when</span> (<span class="enscript-keyword">and</span> gud-tooltip-mode (eq gud-minor-mode 'gdb))
		(gud-tooltip-mode -1)
		(message-box <span class="enscript-string">&quot;Using GUD tooltips in this mode is unsafe\n\
so they have been disabled.&quot;</span>))
	      (<span class="enscript-keyword">unless</span> (null cmd) <span class="enscript-comment">; CMD can be nil if unknown debugger
</span>		(<span class="enscript-keyword">if</span> (memq gud-minor-mode '(gdba gdbmi))
		      (<span class="enscript-keyword">if</span> gdb-macro-info
			  (gdb-enqueue-input
			   (list (concat
				  gdb-server-prefix <span class="enscript-string">&quot;macro expand &quot;</span> expr <span class="enscript-string">&quot;\n&quot;</span>)
				 `(<span class="enscript-keyword">lambda</span> () (gdb-tooltip-print-1 ,expr))))
			(gdb-enqueue-input
			 (list  (concat cmd <span class="enscript-string">&quot;\n&quot;</span>)
 				 `(<span class="enscript-keyword">lambda</span> () (gdb-tooltip-print ,expr)))))
		  (setq gud-tooltip-original-filter (process-filter process))
		  (set-process-filter process 'gud-tooltip-process-output)
		  (gud-basic-call cmd))
		expr))))))))

(provide 'gud)

<span class="enscript-comment">;;; arch-tag: 6d990948-df65-461a-be39-1c7fb83ac4c4
</span><span class="enscript-comment">;;; gud.el ends here
</span></pre>
<hr />
</body></html>