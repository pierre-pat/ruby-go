require 'test/unit'

require_relative "../sgf_reader"


class TestSgfReader < Test::Unit::TestCase

  def initialize(test_name)
    super(test_name)
  end

  def test_1
    game1 = "(;FF[4]EV[go19.ch.10.4.3]PB[kyy]PW[Olivier Lombart]KM[6.5]SZ[19]SO[http://www.littlegolem.com];B[pd];W[pp];B[ce];W[dc];B[dp];W[ee];B[dg];W[cn];B[fq];W[bp];B[cq];W[bq];B[br];W[cp];B[dq];W[dj];B[cc];W[cb];B[bc];W[nc];B[qf];W[pb];B[qc];W[jc];B[qn];W[nq];B[pj];W[ch];B[cg];W[bh];B[bg];W[iq];B[en];W[gr];B[fr];W[ol];B[ql];W[rp];B[ro];W[qo];B[po];W[qp];B[pn];W[no];B[cl];W[dm];B[cj];W[dl];B[di];W[ck];B[ej];W[dk];B[ci];W[bj];B[bi];W[bk];B[ah];W[gc];B[lc];W[ld];B[kd];W[md];B[kc];W[jd];B[ke];W[nf];B[kg];W[oh];B[qh];W[nj];B[hf];W[ff];B[fg];W[gf];B[gg];W[he];B[if];W[ki];B[jp];W[ip];B[jo];W[io];B[jn];W[im];B[in];W[hn];B[jm];W[il];B[jl];W[ik];B[jk];W[jj];B[ho];W[go];B[hm];W[gn];B[ij];W[hj];B[ii];W[gk];B[kj];W[ji];B[lj];W[li];B[mj];W[mi];B[nk];W[ok];B[ni];W[oj];B[nh];W[ng];B[mh];W[lh];B[mg];W[lg];B[nn];W[pi];B[om];W[ml];B[mo];W[mp];B[ln];W[mk];B[qj];W[qi];B[jq];W[ir];B[ar];W[mm];B[oo];W[np];B[mn];W[ri];B[dd];W[ec];B[bb];W[rk];B[pl];W[rg];B[qb];W[pf];B[pe];W[of];B[qg];W[rh];B[ob];W[nb];B[pc];W[sd];B[rc];W[re];B[qe];W[ih];B[hi];W[hh];B[gi];W[hg];B[jh];W[lf];B[kf];W[lp];B[nm];W[kk];B[lr];W[lq];B[kr];W[jr];B[kq];W[mr];B[kb];W[jb];B[ja];W[ia];B[ka];W[hb];B[ie];W[id];B[ed];W[fd];B[db];W[eb];B[ca];W[de];B[cd];W[ek];B[ei];W[em];B[gq];W[gp];B[hr];W[hq];B[gs];W[eo];B[do];W[dn];B[co];W[bo];B[ep];W[fo];B[kl];W[lk];B[lm];W[rm];B[rn];W[rl];B[rj];W[sj];B[rf];W[sf];B[rd];W[se];B[sc];W[sg];B[qm];W[oc];B[pa];W[ko];B[kn];W[ea];B[op];W[oq];B[df];W[fe];B[ef];W[da];B[cb];W[aq];B[gj];W[hk];B[na];W[ma];B[oa];W[mc];B[le];W[me];B[oe];W[nl];B[sp];W[sq];B[so];W[qq];B[ne];W[ls];B[ks];W[aj];B[ms];W[ns];B[ls];W[ai];B[dh];W[fj];B[fi];W[fk];B[je];W[is];B[hs];W[sm];B[sk];W[sl];B[si];W[sh];B[ph];W[oi];B[pg];W[kp];B[og];W[mf];B[kh];W[qk];B[pk];W[si];B[ig];W[fp];B[js];W[hp];B[tt];W[tt];B[tt])"
    reader = SgfReader.new(game1)
    assert_equal(6.5, reader.komi)
    assert_equal(0, reader.handicap)
    assert_equal(19, reader.board_size)
    assert_equal([], reader.handicap_stones)
    moves = reader.to_move_list
    exp_moves = "p16,p4,c15,d17,d4,e15,d13,c6,f3,b4,c3,b3,b2,c4,d3,d10,c17,c18,b17,n17,q14,p18,q17,j17,q6,n3,p10,c12,c13,b12,b13,i3,e6,g2,f2,o8,q8,r4,r5,q5,p5,q4,p6,n5,c8,d7,c10,d8,d11,c9,e10,d9,c11,b10,b11,b9,a12,g17,l17,l16,k16,m16,k17,j16,k15,n14,k13,o12,q12,n10,h14,f14,f13,g14,g13,h15,i14,k11,j4,i4,j5,i5,j6,i7,i6,h6,j7,i8,j8,i9,j9,j10,h5,g5,h7,g6,i10,h10,i11,g9,k10,j11,l10,l11,m10,m11,n9,o9,n11,o10,n12,n13,m12,l12,m13,l13,n6,p11,o7,m8,m5,m4,l6,m9,q10,q11,j3,i2,a2,m7,o5,n4,m6,r11,d16,e17,b18,r9,p8,r13,q18,p14,p15,o14,q13,r12,o18,n18,p17,s16,r17,r15,q15,i12,h11,h12,g11,h13,j12,l14,k14,l4,n7,k9,l2,l3,k2,j2,k3,m2,k18,j18,j19,i19,k19,h18,i15,i16,e16,f16,d18,e18,c19,d15,c16,e9,e11,e7,g3,g4,h2,h3,g1,e5,d5,d6,c5,b5,e4,f5,k8,l9,l7,r7,r6,r8,r10,s10,r14,s14,r16,s15,s17,s13,q7,o17,p19,k5,k6,e19,o4,o3,d14,f15,e14,d19,c18,a3,g10,h9,n19,m19,o19,m17,l15,m15,o15,n8,s4,s3,s5,q3,n15,l1,k1,a10,m1,n1,l1,a11,d12,f10,f11,f9,j15,i1,h1,s7,s9,s8,s11,s12,p12,o11,p13,k4,o13,m14,k12,q9,p9,s11,i13,f4,j1,h4,pass,pass,pass"
    assert_equal(exp_moves, moves)
  end

  def test_2
    game2 = "(;FF[4]EV[go19.mc.2010.mar.1.21]PB[fuego19 bot]PW[Olivier Lombart]KM[0.5]SZ[19]SO[http://www.littlegolem.com]HA[6]AB[pd]AB[dp]AB[pp]AB[dd]AB[pj]AB[dj];W[fq];B[fp];W[dq];B[eq];W[er];B[ep];W[cq];B[fr];W[cp];B[cn];W[co];B[dn];W[nq];B[oc];W[fc];B[ql];W[pr];B[cg];W[qq];B[mc];W[pg];B[nh];W[qi];B[dr];W[cr];B[nk];W[qe];B[hc];W[db];B[jc];W[cc];B[qj];W[qc];B[qd];W[rd];B[re];W[rc];B[qf];W[rf];B[pe];W[se];B[rg];W[qe];B[qg];W[jq];B[es];W[fe];B[ci];W[no];B[bn];W[bo];B[cs];W[bs];B[pb];W[ef];B[ao];W[ap];B[ip];W[pn];B[qn];W[qo];B[jp];W[iq];B[kq];W[lq];B[kr];W[kp];B[hq];W[lr];B[ko];W[lp];B[kg];W[hh];B[ir];W[ce];B[pm];W[rn];B[ek];W[an];B[am];W[ao];B[re];W[sk];B[qm];W[rm];B[ro];W[rp];B[qp];W[po];B[oo];W[on];B[om];W[nn];B[ii];W[bm];B[cm];W[bl];B[cl];W[bk];B[gi];W[ll];B[lm];W[km];B[kl];W[jm];B[lk];W[ln];B[hi];W[hf];B[kc];W[hm];B[ml];W[jo];B[io];W[jn];B[in];W[im];B[bf];W[be];B[bj];W[ri];B[rj];W[sj];B[rl];W[sl];B[qb];W[ph];B[pi];W[qh];B[ae];W[ad];B[ck];W[ds];B[gm];W[ik];B[kj];W[of];B[gb];W[hn];B[gl];W[ho];B[hp];W[fo];B[nf];W[ne];B[oe];W[ng];B[mf];W[mg];B[mh];W[lg];B[lh];W[lf];B[me];W[le];B[md];W[kf];B[jg];W[eh];B[af];W[cd];B[ak];W[fn];B[sf];W[gh];B[hk];W[fi];B[nm];W[ih];B[ji];W[jh];B[kh];W[er];B[fs];W[oh];B[ib];W[oi];B[oj];W[ni];B[mi];W[nj];B[jk];W[hl];B[ij];W[em];B[ls];W[ms];B[dh];W[ks];B[jr];W[cf];B[bg];W[fj];B[gj];W[fk];B[gk];W[fb];B[hd];W[gc];B[fa];W[ea];B[ga];W[dg];B[mj];W[dl];B[il];W[ej];B[gd];W[fd];B[el];W[fl];B[dk];W[dm];B[sd];W[dr];B[ge];W[gf];B[id];W[jl];B[ik];W[ig];B[jf];W[ld];B[lc];W[di];B[ei];W[ha];B[hb];W[di];B[ch];W[ei];B[fm];W[en];B[do];W[mn];B[mm];W[je];B[kd];W[go];B[gq];W[js];B[is];W[ls];B[ke];W[og];B[ie];W[sh];B[if];W[so];B[he];W[fg];B[pf];W[si];B[sg];W[kn];B[rh];W[sm];B[rk];W[gn];B[eo];W[tt];B[tt];W[tt];B[tt])"
    reader = SgfReader.new(game2)
    assert_equal(0.5, reader.komi)
    assert_equal(6, reader.handicap)
    assert_equal(19, reader.board_size)
    assert_equal(["p16","d4","p4","d16","p10","d10"], reader.handicap_stones)
    moves = reader.to_move_list
    exp_moves = "hand:6=p16-d4-p4-d16-p10-d10,f3,f4,d3,e3,e2,e4,c3,f2,c4,c6,c5,d6,n3,o17,f17,q8,p2,c13,q3,m17,p13,n12,q11,d2,c2,n9,q15,h17,d18,j17,c17,q10,q17,q16,r16,r15,r17,q14,r14,p15,s15,r13,q15,q13,j3,e1,f15,c11,n5,b6,b5,c1,b1,p18,e14,a5,a4,i4,p6,q6,q5,j4,i3,k3,l3,k2,k4,h3,l2,k5,l4,k13,h12,i2,c15,p7,r6,e9,a6,a7,a5,r15,s9,q7,r7,r5,r4,q4,p5,o5,o6,o7,n6,i11,b7,c7,b8,c8,b9,g11,l8,l7,k7,k8,j7,l9,l6,h11,h14,k17,h7,m8,j5,i5,j6,i6,i7,b14,b15,b10,r11,r10,s10,r8,s8,q18,p12,p11,q12,a15,a16,c9,d1,g7,i9,k10,o14,g18,h6,g8,h5,h4,f5,n14,n15,o15,n13,m14,m13,m12,l13,l12,l14,m15,l15,m16,k14,j13,e12,a14,c16,a9,f6,s14,g12,h9,f11,n7,i12,j11,j12,k12,e2,f1,o12,i18,o11,o10,n11,m11,n10,j9,h8,i10,e7,l1,m1,d12,k1,j2,c14,b13,f10,g10,f9,g9,f18,h16,g17,f19,e19,g19,d13,m10,d8,i8,e10,g16,f16,e8,f8,d9,d7,s16,d2,g15,g14,i16,j8,i9,i13,j14,l16,l17,d11,e11,h19,h18,d11,c12,e11,f7,e6,d5,m6,m7,j15,k16,g5,g3,j1,i1,l1,k15,o13,i15,s12,i14,s5,h15,f13,p14,s11,s13,k6,r12,s7,r9,g6,e5,pass,pass,pass,pass"
    assert_equal(exp_moves, moves)
  end

end
