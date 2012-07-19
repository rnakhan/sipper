
require 'base_test_case'
require 'message'

class TestIsupParser < BaseTestCase

 def test_isup
    str_IAM = %q{01 00 49 00 00 03 02 00 07 04 10 00 33 63 21 43 00 30 11}.lines.to_a
    str_ACM = %q{06 00 00 00}.lines.to_a
    str_ANM = %q{09 00}.lines.to_a
    str_REL = %q{0C 02 00 03 80 AB 80}.lines.to_a
    str_RLC = %q{10 00}.lines.to_a

    isup_msg1 = ISUP::IsupParser.parse(str_IAM)
    assert_equal("IAM", isup_msg1.msg_type)
    assert_equal("00", isup_msg1.natConInd)
    assert_equal("4900", isup_msg1.fwdCallInd)
    assert_equal("00", isup_msg1.callingPartyCat)
    assert_equal("03", isup_msg1.transMedReq)
    assert_equal("0033361234", isup_msg1.calledPartyNumber)
    
    isup_msg1.natConInd = "11"
    assert_equal("11", isup_msg1.natConInd)
    isup_msg1.fwdCallInd = "4455"
    assert_equal("4455", isup_msg1.fwdCallInd)
    isup_msg1.callingPartyCat = "11"
    assert_equal("11", isup_msg1.callingPartyCat)
    isup_msg1.transMedReq = "02"
    assert_equal("02", isup_msg1.transMedReq)
    isup_msg1.calledPartyNumber = "0044364234"
    assert_equal("0044364234", isup_msg1.calledPartyNumber)
    
    isup_msg2 = ISUP::IsupParser.parse(str_ACM)
    assert_equal("ACM", isup_msg2.msg_type)
    assert_equal("0000", isup_msg2.bckCalInd)
    
    isup_msg2.bckCalInd = "1122"
    assert_equal("1122", isup_msg2.bckCalInd)
    
    
    isup_msg3 = ISUP::IsupParser.parse(str_ANM)
    assert_equal("ANM", isup_msg3.msg_type)
    
    
    isup_msg4 = ISUP::IsupParser.parse(str_REL)
    assert_equal("REL", isup_msg4.msg_type)
    assert_equal(43, isup_msg4.causeVal)
    
    isup_msg4.causeVal = 44
    assert_equal(44, isup_msg4.causeVal)
    
    isup_msg5 = ISUP::IsupParser.parse(str_RLC)
    assert_equal("RLC", isup_msg5.msg_type)
    
  end    
  
end