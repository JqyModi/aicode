import Foundation
import SwiftSoup
import Combine

/// 热词服务，负责从Weblio抓取热搜词
class HotWordDataRepository: HotWordDataRepositoryProtocol {
    func getHotWords(limit: Int) -> AnyPublisher<[WordCloudWord], any Error> {
        return Future<[WordCloudWord], Error> { promise in
            self.fetchWeblioHotWords(limit: limit) { result in
                switch result {
                case .success(let words):
                    promise(.success(words))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 获取Weblio热搜词
    func fetchWeblioHotWords(limit: Int, completion: @escaping (Result<[WordCloudWord], Error>) -> Void) {
        guard let url = URL(string: "https://www.weblio.jp/ranking/") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "DataError", code: -2)))
                return
            }
            do {
                let doc = try SwiftSoup.parse(html)
                // 选中所有 class 以 RankCL 开头的 tr 标签
                let trs = try doc.select("tr[class^=RankCL]")
                let words: [WordCloudWord] = try trs.prefix(limit).compactMap { tr in
                    // 获取排序号
                    let rankText = try tr.select("td.RankBs").text()
                    let maxFrequency = 15
                    let minFrequency = 1
                    let rank = Int(rankText) ?? 1
                    let frequency = max(maxFrequency - rank + 1, minFrequency)
                    // 提取 a 标签的文本作为热词
                    if let a = try tr.select("a").first() {
                        let text = try a.text()
                        return WordCloudWord(text: text, frequency: frequency)
                    }
                    return nil
                }
                completion(.success(words))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// 解析Weblio主页内容
    func parseWeblioHomepage(completion: @escaping (Result<WeblioHomeContent, Error>) -> Void) {
        guard let url = URL(string: "https://www.weblio.jp/") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "DataError", code: -2)))
                return
            }
            
            do {
                let doc = try SwiftSoup.parse(html)
                
                // 解析网站标题
                let title = try doc.title()
                
                // 解析搜索框信息
                let searchForm = try doc.select("form#searchForm").first()
                let searchPlaceholder = try searchForm?.select("input#searchWord").attr("placeholder") ?? ""
                
                // 解析字典类型列表
                let dictionaryTypes = try doc.select(".dictListBoxCl a").map { element in
                    try element.text()
                }
                
                // 解析功能区块
                let features = try doc.select(".mainBoxCl .mainBoxBtm h2").map { element in
                    try element.text()
                }
                
                // 创建结果对象
                let content = WeblioHomeContent(
                    title: title,
                    searchPlaceholder: searchPlaceholder,
                    dictionaryTypes: dictionaryTypes,
                    features: features
                )
                
                completion(.success(content))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// 将解析结果转换为AnyPublisher
    func getWeblioHomeContent() -> AnyPublisher<WeblioHomeContent, Error> {
        return Future<WeblioHomeContent, Error> { promise in
            self.parseWeblioHomepage { result in
                switch result {
                case .success(let content):
                    promise(.success(content))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

}

/// Weblio主页内容模型
struct WeblioHomeContent {
    let title: String
    let searchPlaceholder: String
    let dictionaryTypes: [String]
    let features: [String]
}

/*

`https://www.weblio.jp/ranking/`返回数据格式如下：

<tbody><tr class="RankCLBL">
<td class="RankBs"><span style="color:#f0ba00;">1</span></td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E8%A6%8F%E5%AE%9A?erl=true" title="規定" rel="nofollow">規定</a></td>
</tr>
<tr class="RankCLWL">
<td class="RankBs"><span style="color:#929292;">2</span></td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E5%A4%A7%E5%88%86?erl=true" title="大分" rel="nofollow">大分</a></td>
</tr>
<tr class="RankCLBL">
<td class="RankBs"><span style="color:#d35816;">3</span></td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/localize?erl=true" title="localize" rel="nofollow">localize</a></td>
</tr>
<tr class="RankCLWM">
<td class="RankBs">4</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E6%BD%9C%E5%9C%A8?erl=true" title="潜在" rel="nofollow">潜在</a></td>
</tr>
<tr class="RankCLBM">
<td class="RankBs">5</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E9%A1%95%E3%82%8C%E3%82%8B?erl=true" title="顕れる" rel="nofollow">顕れる</a></td>
</tr>
<tr class="RankCLWM">
<td class="RankBs">6</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E8%96%A9%E8%8B%B1%E6%88%A6%E4%BA%89?erl=true" title="薩英戦争" rel="nofollow">薩英戦争</a></td>
</tr>
<tr class="RankCLBM">
<td class="RankBs">7</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E5%AF%BE%E6%AF%94?erl=true" title="対比" rel="nofollow">対比</a></td>
</tr>
<tr class="RankCLWM">
<td class="RankBs">8</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E4%B8%8A%E3%81%92%E8%86%B3%E6%8D%AE%E3%81%88%E8%86%B3?erl=true" title="上げ膳据え膳" rel="nofollow">上げ膳据え膳</a></td>
</tr>
<tr class="RankCLBM">
<td class="RankBs">9</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E7%84%A1%E7%B7%9A%E6%A8%99%E5%AE%9A%E9%99%B8%E4%B8%8A%E5%B1%80?erl=true" title="無線標定陸上局" rel="nofollow">無線標定陸上局</a></td>
</tr>
<tr class="RankCLWM">
<td class="RankBs">10</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E3%83%9D%E3%82%B9%E3%83%88?erl=true" title="ポスト" rel="nofollow">ポスト</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">11</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E4%B8%8B%E9%96%A2%E6%88%A6%E4%BA%89?erl=true" title="下関戦争" rel="nofollow">下関戦争</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">12</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E5%B8%8C%E6%9C%9B%E3%81%AE%E8%BD%8D?erl=true" title="希望の轍" rel="nofollow">希望の轍</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">13</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E9%8C%AC%E4%B8%B9%E8%A1%93?erl=true" title="錬丹術" rel="nofollow">錬丹術</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">14</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E3%83%AF%E3%82%AA%E3%83%AF%E3%83%BC%E3%83%AB%E3%83%89?erl=true" title="ワオワールド" rel="nofollow">ワオワールド</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">15</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E6%88%90%E3%82%8A%E5%88%87%E3%82%8B?erl=true" title="成り切る" rel="nofollow">成り切る</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">16</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E3%82%B2%E3%83%BC%E3%83%84%E3%82%AD%E3%83%A3%E3%83%91?erl=true" title="ゲーツキャパ" rel="nofollow">ゲーツキャパ</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">17</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E9%9D%A2%E6%8C%81%E3%81%A1?erl=true" title="面持ち" rel="nofollow">面持ち</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">18</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E8%BB%92%E4%B8%A6%E3%81%BF?erl=true" title="軒並み" rel="nofollow">軒並み</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">19</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E3%80%8C%E6%98%8E%E6%97%A5%E5%92%B2%E3%81%8F%E3%81%A4%E3%81%BC%E3%81%BF%E3%81%AB%E3%80%8D%E3%83%AC%E3%82%B3%E3%83%BC%E3%83%87%E3%82%A3%E3%83%B3%E3%82%B0%E7%A7%98%E8%A9%B1?erl=true" title="「明日咲くつぼみに」レコーディング秘話" rel="nofollow">「明日咲くつぼみに」レコーディング秘話</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">20</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E7%AB%8B%E3%81%A6%E6%9B%BF%E3%81%88?erl=true" title="立て替え" rel="nofollow">立て替え</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">21</td>
<td>
<p class="mainRankS"></p>
<a href="https://www.weblio.jp/content/%E3%81%A9%E3%81%A3%E3%81%A1%E3%81%8B?erl=true" title="どっちか" rel="nofollow">どっちか</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">22</td>
<td>
<p class="mainRankS"></p>
<a href="https://www.weblio.jp/content/%E3%81%93%E3%82%8C%E3%81%A7%E3%81%AF?erl=true" title="これでは" rel="nofollow">これでは</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">23</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E8%81%B4%E5%8F%8E?erl=true" title="聴収" rel="nofollow">聴収</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">24</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/1940+-+60?erl=true" title="1940 - 60" rel="nofollow">1940 - 60</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">25</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E3%83%98%E3%83%AA%E3%83%BC%E3%81%AE%E5%AE%9A%E7%90%86?erl=true" title="ヘリーの定理" rel="nofollow">ヘリーの定理</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">26</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E3%81%BE%E3%81%A0?erl=true" title="まだ" rel="nofollow">まだ</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">27</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E8%AA%9E%E5%BD%99?erl=true" title="語彙" rel="nofollow">語彙</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">28</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E7%B8%9B%E3%82%89%E3%82%8C?erl=true" title="縛られ" rel="nofollow">縛られ</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">29</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/DL+site?erl=true" title="DL site" rel="nofollow">DL site</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">30</td>
<td>
<p class="mainRankU"></p>
<a href="https://www.weblio.jp/content/%E3%83%87%E3%82%AB%E3%83%83%E3%83%97%E3%83%AA%E3%83%B3%E3%82%B0?erl=true" title="デカップリング" rel="nofollow">デカップリング</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">31</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E3%82%B5%E3%83%BC%E3%82%AF%E3%83%AB?erl=true" title="サークル" rel="nofollow">サークル</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">32</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E3%81%82%E3%81%AA%E3%81%9F?erl=true" title="あなた" rel="nofollow">あなた</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">33</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/Sun+Set+%28?erl=true" title="Sun Set (" rel="nofollow">Sun Set (</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">34</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/overnight?erl=true" title="overnight" rel="nofollow">overnight</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">35</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E7%9B%B8%E6%A8%A1%E6%B9%BE?erl=true" title="相模湾" rel="nofollow">相模湾</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">36</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%91%E3%82%A4%E3%82%A2%E3%81%95%E3%82%8C%E3%82%8B?erl=true" title="インスパイアされる" rel="nofollow">インスパイアされる</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">37</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E6%9D%BF%E5%BC%B5%E3%82%8A?erl=true" title="板張り" rel="nofollow">板張り</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">38</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E3%82%B8%E3%83%97%E3%82%B7%E3%83%BC%E3%82%AD%E3%83%B3%E3%82%B0%E3%82%B9?erl=true" title="ジプシーキングス" rel="nofollow">ジプシーキングス</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">39</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E5%AE%9A%E7%BE%A9?erl=true" title="定義" rel="nofollow">定義</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">40</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/2004-05?erl=true" title="2004-05" rel="nofollow">2004-05</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">41</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E3%83%A1%E3%83%B3%E3%83%90%E3%83%BC%E3%82%B7%E3%83%83%E3%83%97?erl=true" title="メンバーシップ" rel="nofollow">メンバーシップ</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">42</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E9%A0%82%E6%88%B4?erl=true" title="頂戴" rel="nofollow">頂戴</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">43</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/%E6%B5%AE%E3%81%B6?erl=true" title="浮ぶ" rel="nofollow">浮ぶ</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">44</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E6%96%87%E4%B9%85%E3%81%AE%E6%94%B9%E9%9D%A9?erl=true" title="文久の改革" rel="nofollow">文久の改革</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">45</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E7%94%9F%E9%BA%A6%E4%BA%8B%E4%BB%B6?erl=true" title="生麦事件" rel="nofollow">生麦事件</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">46</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E5%B9%B3%E7%A9%8F?erl=true" title="平穏" rel="nofollow">平穏</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">47</td>
<td>
<p class="mainRankN"></p>
<a href="https://www.weblio.jp/content/Baby+Blue+%28?erl=true" title="Baby Blue (" rel="nofollow">Baby Blue (</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">48</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E5%B8%B0%E5%8C%96%E6%97%A5%E6%9C%AC%E4%BA%BA%E3%81%AE%E6%94%BF%E6%B2%BB%E5%AE%B6%E4%B8%80%E8%A6%A7?erl=true" title="帰化日本人の政治家一覧" rel="nofollow">帰化日本人の政治家一覧</a></td>
</tr>
<tr class="RankCLB">
<td class="RankBs">49</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E3%83%AD%E3%83%83%E3%83%88%E3%83%9E%E3%83%B3%E3%83%AC%E3%83%B3%E3%82%BA%E5%BC%8F?erl=true" title="ロットマンレンズ式" rel="nofollow">ロットマンレンズ式</a></td>
</tr>
<tr class="RankCLW">
<td class="RankBs">50</td>
<td>
<p class="mainRankD"></p>
<a href="https://www.weblio.jp/content/%E6%A6%82%E8%A6%81?erl=true" title="概要" rel="nofollow">概要</a></td>
</tr>
</tbody>

*/