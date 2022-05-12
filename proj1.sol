//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.11;
contract Market {
	// 소비자 구조체
	struct Consumer {
		address payable addr;	// 소비자의 어드레스
		uint amount;	// 입금액
		uint returnPrice;	// 추가된 것 환불 금액
	}

	uint public price;
	address payable public owner;		// 물건 판매자
	uint public numConsumers;	// 구매 희망자
    uint public goalConsumers;		// 판매할 수 있는 수량 
    uint public totalConsumers;	// 판매된 수량
	uint public deadline;		// 판매 마감일
	string public status;		// 현재 판매 현황
	bool public ended;			// 판매 종료여부



	/// 처음 입력 값 -> 물건 가격, 물건 수량
	/// 구매자들이 판매자에게 물건 가격만큼 입금 -> 만약 (가격 * 2) 입금되면 물건 2개 구매
	/// 물건 수량이 0 또는 판매 마감 기한이 되면 판매 종료

	/// + 추가해볼만한 기능
	/// 1. 만약 판매자의 어드레스에서 물건 가격과 수량을 이 컨트렉트로 보내주면 다시 판매 시작
	/// 2. 판매자의 어드레스일 경우, 현재까지 판매된 물건의 개수와 총 판매액 확인 (판매자가 아닐 경우 불가능)
	///

	/// 예외 처리 목록
	/// 1. 
	/// 2. 물건 수량이 0이거나 판매 마감 기한이 지났을 경우, 금액을 다시 돌려줌
	/// 


	mapping (uint => Consumer) public consumers;	// 구매자 관리를 위한 매핑
	
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}
	
	/// 생성자
	constructor(uint _duration, uint _goalAmount, uint _price) {
		owner = payable(msg.sender);

		// 마감일 설정 (Unixtime)
		deadline = block.timestamp + _duration;
		price = _price;

		goalConsumers = _goalAmount;
		status = "Sale";
		ended = false;

		numConsumers = 0;
		totalConsumers = 0;
	}
	

    /// 판매 시에 호출되는 함수
	function sale() payable public {
        // 판매가 끝났다면 처리 중단
		require(!ended);
		

		if(totalConsumers >= goalConsumers){
			status = "End of Sale: Sold Out";
			ended = true;
		} else if(block.timestamp >= deadline) {
			status = "End of Sale: Time Out";
			ended = true;
		} else {
			Consumer storage con = consumers[numConsumers++];
			con.addr = payable(msg.sender);
			con.amount = msg.value;
		
			if (msg.value >= price){
				con.returnPrice = msg.value - price;
			} else {
				con.returnPrice = 0;
			}


			if(!payable(msg.sender).send(con.returnPrice)){
				revert();
			}

			if(!owner.send(con.amount - con.returnPrice)){
				revert();
			}
			totalConsumers++;
		}

		
	}
	
	/**
	function refund() payable public {
		if(!ended){
			uint i = 0;
			while(i <= numConsumers){
				if(msg.sender == consumers[i].addr){
					if(!consumers[i].addr.send(consumers[i].amount)){
						revert();
					}
				} else {
					i++;
				}
			}
		} else {
			status = "Non Refundable : End of Sale";
		}
	}
	**/

	/// 컨트랙트를 소멸시키기 위한 함수
	function kill() public onlyOwner {
		selfdestruct(owner);
	}
}



