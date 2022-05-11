/**
 *Submitted for verification at Etherscan.io on 2019-08-01
*/

pragma solidity >=0.4.22 <0.6.0;

//����owned��Լ
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // ʵ������Ȩת��
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

/**
�Զ����SMMC SZH����
 */
contract TokenERC20 {
    /**
    �������ƣ�����"Smart Mining Chain;Smart Zillion Hyperledger"
     */
    string public name;
    /**
    ���Ҽ��, "SMMC;SZH"
    */ 
    string public symbol;
    /**
    ����tokenʹ�õ�С�����λ�������������Ϊ3������֧��0.001��ʾ.
    */  
    uint8 public decimals = 18;
    
    uint256 public totalSupply;

    // ��mapping����ÿ����ַ��Ӧ�����
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // �洢���˺ŵĿ���
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // �¼�������֪ͨ�ͻ��˽��׷���
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // �¼�������֪ͨ�ͻ��˴��ұ�����
    event Burn(address indexed from, uint256 value);

    /**
     * ��ʼ������
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // ��Ӧ�ķݶ�ݶ����С�Ĵ��ҵ�λ�йأ��ݶ� = ���� * 10 ** decimals��
        balanceOf[msg.sender] = totalSupply;                    // ������ӵ�����еĴ���
        name = tokenName;                                       // ��������Smart Mining Chain;Smart Zillion Hyperledger
        symbol = tokenSymbol;                                   // ���ҷ���
    }

     /**
     * ���ҽ���ת�Ƶ��ڲ�ʵ��
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // ȷ��Ŀ���ַ��Ϊ0x0����Ϊ0x0��ַ��������
        require(_to != address(0x0));
        // ��鷢�������
        require(balanceOf[_from] >= _value);
        // ȷ��ת��Ϊ������
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // ����������齻��
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // ��assert���������߼���
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     *  ���ҽ���ת��
     * ���Լ������������ߣ��˺ŷ���`_value`�����ҵ� `_to`�˺�
     * @param _to �����ߵ�ַ
     * @param _value ת������
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * �˺�֮����ҽ���ת��
     * @param _from �����ߵ�ַ
     * @param _to �����ߵ�ַ
     * @param _value ת������
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * ����ĳ����ַ����Լ�����Դ������������廨�ѵĴ�������
     * ����������`_spender` ���Ѳ����� `_value` ������
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * ��������һ����ַ����Լ�����ң����������ߣ����������໨�ѵĴ�������
     * @param _spender ����Ȩ�ĵ�ַ����Լ��
     * @param _value ���ɻ��Ѵ�����
     * @param _extraData ���͸���Լ�ĸ�������
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * ���ٴ����������˻���ָ��������
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * �����û��˻���ָ��������
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}