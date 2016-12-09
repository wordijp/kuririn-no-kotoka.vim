"=============================================================================
" FILE: kuririn_no_kotoka.vim
" AUTHOR:  wordijp <wordijp at gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:selfpath = g:_kuririn_no_kotoka_autoload_path

" ----------------
" コマンド処理 ---

function! kuririn_no_kotoka#start() abort
  call s:main()
endfunction

function! s:entry(dir) abort
  let l:user = $USER ? $USER : $USERNAME

  let l:ext = ''
  if has('win32') || has('win64')
    let l:ext = '.bat'
  else
    let l:ext = ''
  endif

  execute 'redir > '.s:selfpath.'/'.a:dir.'/'.l:user.l:ext
  redir END
endfunction

function! kuririn_no_kotoka#entry_saiyajin() abort
  call s:entry('saiyajin')
endfunction

function! kuririn_no_kotoka#entry_prince() abort
  call s:entry('prince')
endfunction

function! kuririn_no_kotoka#clear_entry() abort
  let l:user = $USER ? $USER : $USERNAME
  let l:ext = ''
  if has('win32') || has('win64')
    let l:ext = '.bat'
  else
    let l:ext = ''
  endif

  cal delete(s:selfpath.'/saiyajin/'.l:user.l:ext)
  cal delete(s:selfpath.'/prince/'.l:user.l:ext)
endfunction


" --------------
" ライブラリ ---

function! s:_get_statusline()
  let l:line = ''
  redir => l:line
    silent! set statusline?
  redir END
  let l:line = substitute(l:line, '[\r\n]', '', 'g')
  return matchstr(l:line, 'statusline=\zs.\+$')
endfunction

function! s:_get_colorscheme()
  let l:scheme = ''
  redir => l:scheme
    silent! colorscheme
  redir END
  return substitute(l:scheme, '[\r\n]', '', 'g')
endfunction

if !exists('g:loaded_kuririn_no_kotoka_vim')
  let $PATH=s:selfpath.'/saiyajin;'.$PATH
  let $PATH=s:selfpath.'/prince;'.$PATH

  let g:kuririn_no_kotoka_statusline_cache = s:_get_statusline()
  let g:kuririn_no_kotoka_colorscheme_cache = s:_get_colorscheme()
endif
let g:loaded_kuririn_no_kotoka_vim = 1


" --------------------
" 音再生ライブラリ ---

" url) http://thinca.hatenablog.com/entry/20111228/1325077104
"        - スクリプトローカルな関数を手軽に呼び出す
" NOTE : vimprocのローカル関数呼び出しで使用
"
" Call a script local function.
" Usage:
" - S('local_func')
"   -> call s:local_func() in current file.
" - S('plugin/hoge.vim:local_func', 'string', 10)
"   -> call s:local_func('string', 10) in *plugin/hoge.vim.
" - S('plugin/hoge:local_func("string", 10)')
"   -> call s:local_func("string", 10) in *plugin/hoge(.vim)?.
function! s:S(f, ...)
  let [l:file, l:func] =a:f =~# ':' ?  split(a:f, ':') : [expand('%:p'), a:f]
  let fname = matchstr(l:func, '^\w*')

  " Get sourced scripts.
  redir =>slist
  silent scriptnames
  redir END

  let filepat = '\V' . substitute(file, '\\', '/', 'g') . '\v%(\.vim)?$'
  for s in split(slist, "\n")
    let p = matchlist(s, '^\s*\(\d\+\):\s*\(.*\)$')
    if empty(p)
      continue
    endif
    let [nr, sfile] = p[1 : 2]
    let sfile = fnamemodify(sfile, ':p:gs?\\?/?')
    if sfile =~# filepat &&
    \    exists(printf("*\<SNR>%d_%s", nr, fname))
      let cfunc = printf("\<SNR>%d_%s", nr, func)
      break
    endif
  endfor

  if !exists('nr')
    echoerr 'Not sourced: ' . file
    return
  elseif !exists('cfunc')
    let file = fnamemodify(file, ':p')
    echoerr printf(
    \    'File found, but function is not defined: %s: %s()', file, fname)
    return
  endif

  return 0 <= match(func, '^\w*\s*(.*)\s*$')
  \      ? eval(cfunc) : call(cfunc, a:000)
endfunction

function! s:play(wav_file) abort
  if !filereadable(a:wav_file)
    " ファイルが無い
    return ''
  endif

  let l:pre = {}
  for key in keys(vimproc#_get_bg_processes())
    let l:pre[key] = 1
  endfor
  call sound#play_wav(a:wav_file)
  let l:new = {}
  for key in keys(vimproc#_get_bg_processes())
    let l:new[key] = 1
  endfor

  for key in keys(l:pre)
    call remove(l:new, key)
  endfor

  for key in keys(l:new)
    return key
  endfor

  echo 'error len:' . len(l:new)
  return ''
endfunction

" pidのプロセスは終了してるか?
function! s:exit_check(pid) abort
  if a:pid != ''
    let [cond, status] = s:S('autoload/vimproc.vim:libcall', 'vp_waitpid', [a:pid])
    return cond !=# 'run'
  endif
  return 0
endfunction


" ----------------------
" アプリ用ライブラリ ---

function! s:noop()
  " no-op
endfunction


function! s:_get_winpos()
  let l:pos = ''
  redir => l:pos
    silent! winpos
  redir END
  return substitute(l:pos, '[\r\n]', '', 'g')
endfunction

function! s:get_winpos_x()
  return matchstr(s:_get_winpos(), 'X \zs\d\+\ze,')
endfunction

function! s:get_winpos_y()
  return matchstr(s:_get_winpos(), 'Y \zs\d\+\ze$')
endfunction


function! s:_is_dirname(user, reg)
  let s:path = exepath(a:user)
  if s:path == ''
    return 0
  endif

  return fnamemodify(s:path, ':h') =~ a:reg
endfunction

function! s:is_saiyajin(user)
  return s:_is_dirname(a:user, 'saiyajin$')
endfunction

function! s:is_prince(user)
  return s:_is_dirname(a:user, 'prince$')
endfunction

function! s:play_syuinsyuin()
  return s:play(s:selfpath.'/syuinsyuin.wav')
endfunction

" 一定間隔で指定回数funcを読んだあと、最後にnext_funcを呼ぶ
function! s:regist_animate(interval, max_count, func, next_func) abort
  " クロージャ動作をさせるバインド
  let l:Func = a:func
  let l:Next_func = a:next_func
  let l:max_count = a:max_count
  let l:interval = a:interval
  let l:count = 1

  " ループコールバック
  function! s:regist_animate_internal_loop(local, timer) abort
    call a:local.Func() " max_count回数呼ばれる

    if a:local.max_count == 0
      " 無限ループ
      return
    endif

    let a:local.count += 1
    if a:local.count > a:local.max_count
      call timer_stop(a:timer)
      call s:regist_animate_internal_next(a:local.Next_func)
    endif
  endfunction
  call timer_start(a:interval, function('s:regist_animate_internal_loop', [l:]), {'repeat': -1})

  " 終了時コールバック
  function! s:regist_animate_internal_next(next_func) abort
    let l:Next_func = a:next_func

    function! s:regist_animate_internal_next_internal(local, timer) abort
      call a:local.Next_func() " max_count回数後に呼ばれる
    endfunction

    " NOTE : 非同期でa:local.Next_funcを呼び出し、ループコールバック関数の使用中を解除する
    call timer_start(0, function('s:regist_animate_internal_next_internal', [l:]), {'repeat': 1})
  endfunction
endfunction


" -----------------------------------------------

" ------------------
" アプリロジック ---

function! s:main()
  let l:user = $USER ? $USER : $USERNAME

  if s:is_saiyajin(l:user)
    call s:saiyajin_phase_1()
  elseif s:is_prince(l:user)
    call s:prince_phase_1()
  else
    echo 'あなたはサイヤ人でも王子でもありません'
  endif
endfunction

let s:start_winpos = {'x': s:get_winpos_x(), 'y': s:get_winpos_y()}

" NOTE : phaseについて
"        コルーチンが無いので、Stateパターンっぽく書く


" サイヤ人Phase ---

" スーパーサイヤ人になる
" NOTE : 悟空が初めてスーパーサイヤ人になる流れ
" url) https://www.youtube.com/watch?v=7IYkjyWhZ5g
"   1. (0:52) 肩を上下に震わせる(弱)
"   2. (0:55) 許さん、よくも！、よくも！
"   skip 3. (1:11) 雷鳴が降る
"   skip 4. (1:40) よくも！、よくも！
"   5. (1:48) あ、なりそう！、なりそう！
"   6. (2:12) スーパーサイヤ人化
"   7. (2:15) ｼｭｲﾝｼｭｲﾝ

"   1. (0:52) 肩を上下に震わせる(弱)
function! s:saiyajin_phase_1() abort
  " generated by gatagatable.py
  let l:gatagatable = [
  \ {'x':  0, 'y':  8},
  \ {'x':  0, 'y':  9},
  \ {'x':  0, 'y':  8},
  \ {'x':  0, 'y':  6},
  \ {'x':  0, 'y':  7},
  \ {'x':  0, 'y':  7},
  \ {'x':  0, 'y':  5},
  \ {'x':  0, 'y':  9},
  \ {'x':  0, 'y':  4},
  \ {'x':  0, 'y':  7},
  \]
  let l:count = 0
  function! s:saiyajin_phase_1_internal_loop(local) abort
    let l:x = s:start_winpos.x + a:local.gatagatable[a:local.count].x
    let l:y = s:start_winpos.y + a:local.gatagatable[a:local.count].y

    execute 'winpos '.l:x.' '.l:y

    let a:local.count += 1
    if a:local.count >= len(a:local.gatagatable)
      let a:local.count = 0
    endif
  endfunction

  function! s:saiyajin_phase_1_internal_done() abort
    call s:saiyajin_phase_2()
  endfunction

  call s:regist_animate(50, 40, function('s:saiyajin_phase_1_internal_loop', [l:]), function('s:saiyajin_phase_1_internal_done'))
endfunction

"   2. (0:55) 許さん、よくも！、よくも！
function! s:saiyajin_phase_2() abort
  " セリフ
  let l:loop_count = 0
  function! s:saiyajin_phase_2_internal_loop(local) abort
    if a:local.loop_count == 0
      set statusline=ゆ
    elseif a:local.loop_count == 1
      set statusline=ゆ、許さん・・・！
    elseif a:local.loop_count == 2
      set statusline=ゆ、許さん・・・！、よくも・・・
    elseif a:local.loop_count == 3
      set statusline=ゆ、許さん・・・！、よくも・・・よくも・・・
    elseif a:local.loop_count == 4
      " no-op : タメを作る
    elseif a:local.loop_count == 5
      " no-op : タメを作る
    elseif a:local.loop_count == 6
      set statusline=つっ・・・！
    end

    let a:local.loop_count += 1
  endfunction

  " 振動
  " generated by gatagatable.py
  let l:loop2_gatagatable = [
  \ {'x':  0, 'y':  4},
  \ {'x':  0, 'y':  6},
  \ {'x':  0, 'y':  3},
  \ {'x':  0, 'y':  3},
  \ {'x':  0, 'y':  3},
  \ {'x':  0, 'y':  5},
  \ {'x':  0, 'y':  4},
  \ {'x':  0, 'y':  5},
  \]
  let l:loop2_count = 0
  function! s:saiyajin_phase_2_internal_loop2(local) abort
    let l:x = s:start_winpos.x + a:local.loop2_gatagatable[a:local.loop2_count].x
    let l:y = s:start_winpos.y + a:local.loop2_gatagatable[a:local.loop2_count].y

    execute 'winpos '.l:x.' '.l:y

    let a:local.loop2_count += 1
    if a:local.loop2_count >= len(a:local.loop2_gatagatable)
      let a:local.loop2_count = 0
    endif
  endfunction

  let l:remain = 0
  function! s:saiyajin_phase_2_internal_done(local) abort
    let a:local.remain -= 1
    if a:local.remain <= 0
      " 全アニメーション終了
      set statusline=%!g:kuririn_no_kotoka_statusline_cache
      call s:saiyajin_phase_5()
    endif
  endfunction

  " 異なるFPSのアニメーションを合成する
  " NOTE : それぞれの合計時間を合わせる
  call s:regist_animate(600, 7, function('s:saiyajin_phase_2_internal_loop', [l:]), function('s:saiyajin_phase_2_internal_done', [l:]))
  let l:remain += 1
  call s:regist_animate(50, 84, function('s:saiyajin_phase_2_internal_loop2', [l:]), function('s:saiyajin_phase_2_internal_done', [l:]))
  let l:remain += 1
endfunction

"   5. (1:48) あ、なりそう！、なりそう！
function! s:saiyajin_phase_5() abort

  let l:count = 0

  " 色
  let l:narisou_table = [0, 1, 2, 3, 3, 2, 1, 0, 0, 1, 2, 3, 3, 2, 1, 0]
  let l:prev_n = -1
  function! s:saiyajin_phase_5_internal_loop(local) abort
    let l:n = a:local.narisou_table[a:local.count]
    if l:n != a:local.prev_n
      if l:n > 0
        execute 'source '.s:selfpath.'/scheme/narisou_'.l:n.'.vim'
      else
        execute 'colorscheme '.g:kuririn_no_kotoka_colorscheme_cache
      endif
      let a:local.prev_n = l:n
    endif

    let a:local.count += 1
  endfunction

  " 振動
  " 手入力
  " NOTE : 金色の時に頭を上げる
  let l:loop2_gatagatable = [
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    3},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    4},
  \ {'x':   0, 'y':    3},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    2},
  \ {'x':   1, 'y':   -6},
  \ {'x':  -1, 'y':  -10},
  \ {'x':   1, 'y':  -12},
  \ {'x':  -1, 'y':  -11},
  \ {'x':   1, 'y':   -6},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    3},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    4},
  \ {'x':   0, 'y':    3},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    2},
  \ {'x':   0, 'y':    2},
  \ {'x':   1, 'y':   -6},
  \ {'x':  -1, 'y':  -10},
  \ {'x':   1, 'y':  -12},
  \ {'x':  -1, 'y':  -11},
  \ {'x':   1, 'y':   -6},
  \]
  let l:loop2_count = 0
  function! s:saiyajin_phase_5_internal_loop2(local) abort
    let l:x = s:start_winpos.x + a:local.loop2_gatagatable[a:local.loop2_count].x
    let l:y = s:start_winpos.y + a:local.loop2_gatagatable[a:local.loop2_count].y

    execute 'winpos '.l:x.' '.l:y

    let a:local.loop2_count += 1
    if a:local.loop2_count >= len(a:local.loop2_gatagatable)
      let a:local.loop2_count = 0
    endif
  endfunction

  let l:remain = 0
  function! s:saiyajin_phase_5_internal_done(local) abort
    let a:local.remain -= 1
    if a:local.remain <= 0
      call s:saiyajin_phase_6()
    endif
  endfunction

  call s:regist_animate(100, len(l:narisou_table), function('s:saiyajin_phase_5_internal_loop', [l:]), function('s:saiyajin_phase_5_internal_done', [l:]))
  let l:remain += 1
  call s:regist_animate(50, len(l:narisou_table) * 2, function('s:saiyajin_phase_5_internal_loop2', [l:]), function('s:saiyajin_phase_5_internal_done', [l:]))
  let l:remain += 1
endfunction

"   6. (2:12) スーパーサイヤ人化
function! s:saiyajin_phase_6() abort
  let l:loop_count = 0
  function! s:saiyajin_phase_6_internal_loop(local) abort
    if a:local.loop_count < 7
      let g:kuririn_no_kotoka_statusline_new = 'ヴ'
      for i in range(1, a:local.loop_count)
        let g:kuririn_no_kotoka_statusline_new = g:kuririn_no_kotoka_statusline_new.'ア゛'
      endfor
      set statusline=%!g:kuririn_no_kotoka_statusline_new
    endif

    let a:local.loop_count += 1
  endfunction

  function! s:saiyajin_phase_6_internal_done() abort
    set statusline=%!g:kuririn_no_kotoka_statusline_cache
    call s:saiyajin_phase_7()
  endfunction

  call s:regist_animate(100, 18, function('s:saiyajin_phase_6_internal_loop', [l:]), function('s:saiyajin_phase_6_internal_done'))
endfunction

"   7. (2:15) ｼｭｲﾝｼｭｲﾝ
function! s:saiyajin_phase_7() abort

  try
    " エラー出るので握るつぶす
    execute 'source '.s:selfpath.'/scheme/golden.vim'
  catch
  endtry

  let l:pid = s:play_syuinsyuin()

  function! s:saiyajin_phase_7_internal_loop(local) abort
    " NOTE : ループ再生は未対応なので、自前でループさせる
    if s:exit_check(a:local.pid)
      let a:local.pid = s:play_syuinsyuin()
    endif
  endfunction

  call s:regist_animate(100, 0, function('s:saiyajin_phase_7_internal_loop', [l:]), function('s:noop'))
endfunction


" <del>へたれ</del>王子Phase ---
" ガタガタ震える

function! s:prince_phase_1() abort
  " generated by gatagatable.py
  let l:gatagatable = [
  \ {'x':  7, 'y':  4},
  \ {'x':  7, 'y':  5},
  \ {'x':  6, 'y':  6},
  \ {'x':  3, 'y':  5},
  \ {'x':  3, 'y':  5},
  \ {'x':  7, 'y':  7},
  \ {'x':  6, 'y':  3},
  \ {'x':  4, 'y':  5},
  \ {'x':  5, 'y':  5},
  \ {'x':  7, 'y':  7},
  \]
  let l:count = 0
  function! s:prince_phase_1_internal_gatagata(local) abort
    let l:x = s:start_winpos.x + a:local.gatagatable[a:local.count].x
    let l:y = s:start_winpos.y + a:local.gatagatable[a:local.count].y

    execute 'winpos '.l:x.' '.l:y

    let a:local.count += 1
    if a:local.count >= len(a:local.gatagatable)
      let a:local.count = 0
    endif
  endfunction

  " ひたすらガタガタ
  call s:regist_animate(50, 0, function('s:prince_phase_1_internal_gatagata', [l:]), function('s:noop'))
endfunction

