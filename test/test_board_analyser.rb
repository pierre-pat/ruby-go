require 'test/unit'

require_relative "../controller"
require_relative "../human_player"
require_relative "../logging"
require_relative "../board_analyser"

# NB: for debugging think of using analyser.debug_dump


class TestBoardAnalyser < Test::Unit::TestCase

  def init_board(size=5, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
    @goban = @controller.goban
  end

  def initialize(x)
    super(x)
  end

  def test_small_game
    init_board(9)
    # 9 ++O@@++++
    # 8 +@OO@++@+
    # 7 OOOO@@@++
    # 6 ++OOOOO@@
    # 5 OO@@O@@@@
    # 4 @@@+OOOO@
    # 3 O@@@@@O+O
    # 2 +++@OOO++
    # 1 +++@@O+++
    #   abcdefghi
    game2 = "c3,c6,e7,g3,g7,e2,d2,b4,b3,c7,g5,h4,h5,d8,e8,e5,c4,b5,e3,f2,c5,f6,f7,g6,h6,d7,a4,a5,b6,a3,a6,b7,a4,a7,d9,c9,b8,e6,d5,d6,e9,g4,f5,f4,e1,f1,d1,i5,i6,e4,i4,i3,h8,c8,d3,i5,f3,g2,i4,b5,b4,a5,i5"
    @controller.play_moves(game2)
    final_pos = "++O@@++++,+@OO@++@+,OOOO@@@++,++OOOOO@@,OO@@O@@@@,@@@+OOOO@,O@@@@@O+O,+++@OOO++,+++@@O+++"
    assert_equal(final_pos, @goban.image?);

    @controller.play_moves("pass,pass")
    @boan = @controller.analyser
    # we do not test private method anymore
    # tmp_zones = "FFO@@EEEE,F@OO@EE@E,OOOO@@@EE,DDOOOOO@@,OO@@O@@@@,@@@COOOO@,O@@@@@OBO,AAA@OOOBB,AAA@@OBBB"
    # assert_equal(tmp_zones, @boan.image?)
    final_zones = "::O@@----,:&OO@--@-,OOOO@@@--,::OOOOO@@,OO@@O@@@@,@@@?OOOO@,#@@@@@O:O,---@OOO::,---@@O:::"
    # @boan.debug_dump if $debug
    assert_equal(final_zones, @goban.image?)
    prisoners = Group.prisoners?(@goban)
    assert_equal([4,5], prisoners)
    assert_equal([4+1,5+1], @boan.prisoners)
    assert_equal([16,12], @boan.scores)
    
    @boan.restore
    assert_equal(final_pos, @goban.image?);
  end

  def test_big_game_1
    game = "(;FF[4]EV[go19.mc.2010.mar.1.21]PB[fuego19 bot]PW[Olivier Lombart]KM[0.5]SZ[19]SO[http://www.littlegolem.com]HA[6]AB[pd]AB[dp]AB[pp]AB[dd]AB[pj]AB[dj];W[fq];B[fp];W[dq];B[eq];W[er];B[ep];W[cq];B[fr];W[cp];B[cn];W[co];B[dn];W[nq];B[oc];W[fc];B[ql];W[pr];B[cg];W[qq];B[mc];W[pg];B[nh];W[qi];B[dr];W[cr];B[nk];W[qe];B[hc];W[db];B[jc];W[cc];B[qj];W[qc];B[qd];W[rd];B[re];W[rc];B[qf];W[rf];B[pe];W[se];B[rg];W[qe];B[qg];W[jq];B[es];W[fe];B[ci];W[no];B[bn];W[bo];B[cs];W[bs];B[pb];W[ef];B[ao];W[ap];B[ip];W[pn];B[qn];W[qo];B[jp];W[iq];B[kq];W[lq];B[kr];W[kp];B[hq];W[lr];B[ko];W[lp];B[kg];W[hh];B[ir];W[ce];B[pm];W[rn];B[ek];W[an];B[am];W[ao];B[re];W[sk];B[qm];W[rm];B[ro];W[rp];B[qp];W[po];B[oo];W[on];B[om];W[nn];B[ii];W[bm];B[cm];W[bl];B[cl];W[bk];B[gi];W[ll];B[lm];W[km];B[kl];W[jm];B[lk];W[ln];B[hi];W[hf];B[kc];W[hm];B[ml];W[jo];B[io];W[jn];B[in];W[im];B[bf];W[be];B[bj];W[ri];B[rj];W[sj];B[rl];W[sl];B[qb];W[ph];B[pi];W[qh];B[ae];W[ad];B[ck];W[ds];B[gm];W[ik];B[kj];W[of];B[gb];W[hn];B[gl];W[ho];B[hp];W[fo];B[nf];W[ne];B[oe];W[ng];B[mf];W[mg];B[mh];W[lg];B[lh];W[lf];B[me];W[le];B[md];W[kf];B[jg];W[eh];B[af];W[cd];B[ak];W[fn];B[sf];W[gh];B[hk];W[fi];B[nm];W[ih];B[ji];W[jh];B[kh];W[er];B[fs];W[oh];B[ib];W[oi];B[oj];W[ni];B[mi];W[nj];B[jk];W[hl];B[ij];W[em];B[ls];W[ms];B[dh];W[ks];B[jr];W[cf];B[bg];W[fj];B[gj];W[fk];B[gk];W[fb];B[hd];W[gc];B[fa];W[ea];B[ga];W[dg];B[mj];W[dl];B[il];W[ej];B[gd];W[fd];B[el];W[fl];B[dk];W[dm];B[sd];W[dr];B[ge];W[gf];B[id];W[jl];B[ik];W[ig];B[jf];W[ld];B[lc];W[di];B[ei];W[ha];B[hb];W[di];B[ch];W[ei];B[fm];W[en];B[do];W[mn];B[mm];W[je];B[kd];W[go];B[gq];W[js];B[is];W[ls];B[ke];W[og];B[ie];W[sh];B[if];W[so];B[he];W[fg];B[pf];W[si];B[sg];W[kn];B[rh];W[sm];B[rk];W[gn];B[eo];W[tt];B[tt];W[tt];B[tt])"
    init_board()
    @controller.play_moves(game)
    @goban = @controller.goban
    @boan = @controller.analyser
    final_zones = "::::O@@#-----------,:::O:O@@@------@@--,::O::OO@-@@@@-@-##-,O:O&:O@@@-@O@--@@\#@,@OO::O@@@\#@O@\#@@-@-,@@O:O:OO@@OO@@O@@-@,-@@O:O::O@@OOOOO@@@,--@@O:OOOO@@@@OOO@O,--@OOO@@@@--@OO@OOO,-@-@OO@-@-@-@O@@@@O,@\#@@@O@@@@-@-@---@O,-\#@O@O@O@O@-@---@@O,@\#@OO@@OOOO@@@@@@OO,O@@@OOOO@OOOOOOO@O:,OOO@@OOO@O&::O&OO:O,O:O@@@?@@@OO:::&&O:,::OO@-@@--@O:O::O::,::OOO@--@@@O:::O:::,:O:O@@--@OOOO::::::"
    # @boan.debug_dump if $debug
    assert_equal(final_zones, @goban.image?)
    prisoners = Group.prisoners?(@goban)
    assert_equal([7,11], prisoners)
    assert_equal([7+5,11+9], @boan.prisoners)
    assert_equal([67,59], @boan.scores)
  end
  
  def test_big_game_2
    # NB: game was initially downloaded with an extra illegal move (dupe) at the end (;W[aq])
    game = "(;FF[4]EV[go19.ch.10.4.3]PB[kyy]PW[Olivier Lombart]KM[6.5]SZ[19]SO[http://www.littlegolem.com];B[pd];W[pp];B[ce];W[dc];B[dp];W[ee];B[dg];W[cn];B[fq];W[bp];B[cq];W[bq];B[br];W[cp];B[dq];W[dj];B[cc];W[cb];B[bc];W[nc];B[qf];W[pb];B[qc];W[jc];B[qn];W[nq];B[pj];W[ch];B[cg];W[bh];B[bg];W[iq];B[en];W[gr];B[fr];W[ol];B[ql];W[rp];B[ro];W[qo];B[po];W[qp];B[pn];W[no];B[cl];W[dm];B[cj];W[dl];B[di];W[ck];B[ej];W[dk];B[ci];W[bj];B[bi];W[bk];B[ah];W[gc];B[lc];W[ld];B[kd];W[md];B[kc];W[jd];B[ke];W[nf];B[kg];W[oh];B[qh];W[nj];B[hf];W[ff];B[fg];W[gf];B[gg];W[he];B[if];W[ki];B[jp];W[ip];B[jo];W[io];B[jn];W[im];B[in];W[hn];B[jm];W[il];B[jl];W[ik];B[jk];W[jj];B[ho];W[go];B[hm];W[gn];B[ij];W[hj];B[ii];W[gk];B[kj];W[ji];B[lj];W[li];B[mj];W[mi];B[nk];W[ok];B[ni];W[oj];B[nh];W[ng];B[mh];W[lh];B[mg];W[lg];B[nn];W[pi];B[om];W[ml];B[mo];W[mp];B[ln];W[mk];B[qj];W[qi];B[jq];W[ir];B[ar];W[mm];B[oo];W[np];B[mn];W[ri];B[dd];W[ec];B[bb];W[rk];B[pl];W[rg];B[qb];W[pf];B[pe];W[of];B[qg];W[rh];B[ob];W[nb];B[pc];W[sd];B[rc];W[re];B[qe];W[ih];B[hi];W[hh];B[gi];W[hg];B[jh];W[lf];B[kf];W[lp];B[nm];W[kk];B[lr];W[lq];B[kr];W[jr];B[kq];W[mr];B[kb];W[jb];B[ja];W[ia];B[ka];W[hb];B[ie];W[id];B[ed];W[fd];B[db];W[eb];B[ca];W[de];B[cd];W[ek];B[ei];W[em];B[gq];W[gp];B[hr];W[hq];B[gs];W[eo];B[do];W[dn];B[co];W[bo];B[ep];W[fo];B[kl];W[lk];B[lm];W[rm];B[rn];W[rl];B[rj];W[sj];B[rf];W[sf];B[rd];W[se];B[sc];W[sg];B[qm];W[oc];B[pa];W[ko];B[kn];W[ea];B[op];W[oq];B[df];W[fe];B[ef];W[da];B[cb];W[aq];B[gj];W[hk];B[na];W[ma];B[oa];W[mc];B[le];W[me];B[oe];W[nl];B[sp];W[sq];B[so];W[qq];B[ne];W[ls];B[ks];W[aj];B[ms];W[ns];B[ls];W[ai];B[dh];W[fj];B[fi];W[fk];B[je];W[is];B[hs];W[sm];B[sk];W[sl];B[si];W[sh];B[ph];W[oi];B[pg];W[kp];B[og];W[mf];B[kh];W[qk];B[pk];W[si];B[ig];W[fp];B[js];W[hp];B[tt];W[tt];B[tt])"
    init_board()
    @controller.play_moves(game)
    @goban = @controller.goban
    @boan = @controller.analyser
    final_zones = "--@OO:::O@@?O@@@---,-@@@O::O:O@??O@-@--,-@@OO:O::O@@OOO@@@@,--@@@O::OO@OO??@-@O,--@OOO:O@@@@O@@@@OO,---@@OO@@-@OOOOO@@O,-@@@-@@\#@-@O:O@@@OO,@--@---#\#@@O::O@@OO,O@@@@@@@@OOOO:OOOOO,OO@O@O@O@O:::OO@@@O,:OOOOOOOO@OOO:O@OO:,::&O::::O@@?OOO@@OO,:::OO::&O@-@O@@-@OO,::OO&:OO@@@@@@-@@@?,:O@@OOO:O@O?@O@@O@@,:OO@@OOOO@OOOO@OOO@,OO@@-@@OO@@O:OO:O:O,@@---@-@OO@@O::::::,------@@O@@@@O:::::"
    # @boan.debug_dump if $debug
    assert_equal(final_zones, @goban.image?)
    prisoners = Group.prisoners?(@goban)
    assert_equal([11,6], prisoners)
    assert_equal([11+3,6+3], @boan.prisoners)
    assert_equal([44,56], @boan.scores)
  end

end
