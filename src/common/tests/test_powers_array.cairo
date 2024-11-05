use integrity::common::powers_array::powers_array;

#[test]
#[available_gas(9999999999)]
fn test_powers_array_0() {
    assert(
        powers_array(
            8939912, 818129, 20
        ) == array![
            8939912,
            7314001264648,
            5983796540645203592,
            4895517480001519769519368,
            4005164820396163367517111022472,
            3276741489345892739703406523703994888,
            2680797237937065881240808275831425633724552,
            2193237963476213772353661233897688422293434003208,
            1794351581820831297361928511627481931242504867610557832,
            1468011065283494888479417211289280164925499264833358068536328,
            1201022424829320389616777123654887492050333788038850403253557490312,
            982591275403187061036784251398649448983647531674436641563429735991466248,
            578798470452897618157604965420111599212769637660707731620770014798701463210,
            64897154080296376744067237228250081708262563085217890232603082073306308506,
            3570855249317241879864852740142508196913411001040536104120285926502587208042,
            296822332749766136374571546668437122679929036177024349694690002078960735182,
            1236122849353634764512930791639952640937217569299656172828823579696019234568,
            1554236852172389644389568626430917567621998253096118392892400158736329812430,
            2650676934462094271980856993953144424194696459174707922062388312529884397184,
            1618947405625354125126437534914831315303549411394098205806855140739005342069
        ],
        'Invalid value'
    );
}
