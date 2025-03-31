#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import json
import csv
import os
from datetime import datetime
import time

# 创建保存数据的目录
output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'review_data')
os.makedirs(output_dir, exist_ok=True)

# 请求头和Cookie
headers = {
    'accept': 'application/vnd.api+json, application/json, text/csv',
    'accept-language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
    'content-type': 'application/json',
    'priority': 'u=1, i',
    'referer': 'https://appstoreconnect.apple.com/apps/1021094295/distribution/ratings/ios',
    'sec-ch-ua': '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"macOS"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
    'x-csrf-itc': '[asc-ui]'
}

# 这里需要替换为您的实际Cookie
cookies = 'geo=HK; s_fid=16FB895008CAB6C1-0E94340A7EF54FD4; s_cc=true; s_vi=[CS]v1|33F3BA190FE22EF3-40000156404AF2AA[CE]; s_sq=%5B%5BB%5D%5D; dslang=CN-ZH; site=CHN; myacinfo=DAWTKNV323952cf8084a204fb20ab2508441a07d02d38a7dd94ba26d3900dc07796e907f4ba7fd4a497def3ae905a0849608e9eb2286f8020512e1dbd8d68e96511f50c7c7bfb77de4b00face7625178c354dc929ecf059b80769f2dfe3b3f408cb9b42964637068e9f94db64f2cb0460ccea415cb3d5dd9f963e00b0455df6b28675c374b0eeb536f39ada3982186e89eae65428df5d110a220c8b4438a6a8b9163aeaf09f1287a79fadd73e5aa46e330dc4439514dd52c3a87e0e92cb4042606941d2aa644099586c2c90cda1b4b1e225f6b8c6e15632bcaf17aae58831bbbb511dfad89de3c046faa8c17f5fe0975495926eb3e16857956edcae7e663ed3ad9c5bef88d12547460ada7032047d74772a474ad82a7deaeb8d245919f107ae5b5ff981c9f988b85a967e2aeb6c713553bfe03749a6795ce9752c0a7be0eb16fb5aa85e93a749af2041d76fed8b167fd862247332b00717c87479e3eb011a3bc1bc9b15e14628e52af986cd724cacae904330281b6e82c7c697e38277cd2bdb9af59956ce0431994c620c90ec542e6cf1a92a9531fadee2109aba65f6de2f5197c9894a75cde07a18df63eee243f018d1120965475729d8830a55890c646ec295bcfeb06c9c0781ffeb3baf9a02be7eb82a18b7ec8500a9512c518f0b527c034945ebe26fef4cb513a307af21b25fd7e5e36a5574277c4254faeec77fa25f598263632ff2ab956061c9e81990f64717c7095bdf8fad597e81b357217de137a575f8249cbfec5a9f82aff1f102aa5ff81d39711eeb9e1a807c41c5abaec129419478f6d75be2f8dcdfcc32e393fd891e9eeff6ec533e2e4e0d63ace12d22707e406857d5cbae6739456b9847f52b96592896d52693f321b863ecf62b38fc2be3d08343f1825eb585a47V3; dc=mr; itctx=eyJjcCI6IjNiNTg0OGMyLTNkNDMtNDQ4Mi05ZTQ1LTMyNDQ0ZTI5ZWMyMSIsImRzIjoxODEyNDI3ODM5LCJleCI6IjIwMjUtMy0zMSAyMzoyMzo1NyJ9|n3c9g8nts82fmi1p3mncmhilei|7E54_rh_079b9IDX7frAOUZgd-I; itcdq=0; dqsid=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NDM0MzQ2NDgsImp0aSI6Imc1QWZ3dE1NNUViMDlrZkFYd3RiYmcifQ.TNg1FDAGEC0i_oAk9_MAEckhI1VUwnl89XnVIhMjzuc; wosid=bTECv06oZ0z4vbhgZDGvDw; woinst=220069'

# 将Cookie字符串转换为字典
cookie_dict = {}
for item in cookies.split('; '):
    if '=' in item:
        key, value = item.split('=', 1)
        cookie_dict[key] = value

# 定义不同的排序和评分参数
sort_types = {
    'most_helpful': 'REVIEW_SORT_ORDER_HELPFUL_SUMMARY_ALIGNED',
    'most_recent': 'REVIEW_SORT_ORDER_MOST_RECENT',
    'highest_rating': 'REVIEW_SORT_ORDER_RATING_DESC',
    'lowest_rating': 'REVIEW_SORT_ORDER_RATING_ASC'
}

rating_types = {
    '1_star': 'RATING_1',
    '2_star': 'RATING_2',
    '3_star': 'RATING_3',
    '4_star': 'RATING_4',
    '5_star': 'RATING_5'
}

# 基础URL
base_url = 'https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/1021094295/platforms/ios/reviews'

def fetch_reviews(sort_type, rating, limit=200):
    """获取指定排序和评分的评论"""
    params = {
        'limit': limit,
        'sort': sort_types[sort_type],
        'rating': rating_types[rating]
    }
    
    url = f"{base_url}?limit={limit}&sort={sort_types[sort_type]}&rating={rating_types[rating]}"
    
    try:
        response = requests.get(url, headers=headers, cookies=cookie_dict)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"请求失败，状态码: {response.status_code}")
            return None
    except Exception as e:
        print(f"请求异常: {e}")
        return None

def save_to_json(data, filename):
    """将数据保存为JSON文件"""
    filepath = os.path.join(output_dir, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"数据已保存到 {filepath}")

def save_to_csv(reviews, filename):
    """将评论数据保存为CSV文件"""
    filepath = os.path.join(output_dir, filename)
    
    # 提取评论中的关键字段
    csv_data = []
    for review_item in reviews:
        review = review_item.get('value', {})
        csv_data.append({
            'id': review.get('id'),
            'rating': review.get('rating'),
            'title': review.get('title', ''),
            'review': review.get('review', ''),
            'nickname': review.get('nickname', ''),
            'appVersion': review.get('appVersionString', ''),
            'lastModified': review.get('lastModified'),
            'helpfulViews': review.get('helpfulViews', 0),
            'totalViews': review.get('totalViews', 0)
        })
    
    # 写入CSV
    if csv_data:
        keys = csv_data[0].keys()
        with open(filepath, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(csv_data)
        print(f"CSV数据已保存到 {filepath}")
    else:
        print("没有数据可保存")

def process_reviews():
    """处理评论数据的主函数"""
    # 获取低分评论（1星和2星）
    print("正在获取最有帮助的1星评论...")
    one_star_helpful = fetch_reviews('most_helpful', '1_star')
    time.sleep(1)  # 避免请求过于频繁
    
    print("正在获取最有帮助的2星评论...")
    two_star_helpful = fetch_reviews('most_helpful', '2_star')
    time.sleep(1)
    
    # 获取高分评论（用于交叉验证）
    print("正在获取最有帮助的4星评论...")
    four_star_helpful = fetch_reviews('most_helpful', '4_star')
    time.sleep(1)
    
    print("正在获取最有帮助的5星评论...")
    five_star_helpful = fetch_reviews('most_helpful', '5_star')
    
    # 保存原始JSON数据
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if one_star_helpful:
        save_to_json(one_star_helpful, f'one_star_helpful_{timestamp}.json')
        if 'reviews' in one_star_helpful.get('data', {}):
            save_to_csv(one_star_helpful['data']['reviews'], f'one_star_helpful_{timestamp}.csv')
    
    if two_star_helpful:
        save_to_json(two_star_helpful, f'two_star_helpful_{timestamp}.json')
        if 'reviews' in two_star_helpful.get('data', {}):
            save_to_csv(two_star_helpful['data']['reviews'], f'two_star_helpful_{timestamp}.csv')
    
    if four_star_helpful:
        save_to_json(four_star_helpful, f'four_star_helpful_{timestamp}.json')
        if 'reviews' in four_star_helpful.get('data', {}):
            save_to_csv(four_star_helpful['data']['reviews'], f'four_star_helpful_{timestamp}.csv')
    
    if five_star_helpful:
        save_to_json(five_star_helpful, f'five_star_helpful_{timestamp}.json')
        if 'reviews' in five_star_helpful.get('data', {}):
            save_to_csv(five_star_helpful['data']['reviews'], f'five_star_helpful_{timestamp}.csv')
    
    # 合并低分评论
    low_rating_reviews = []
    
    if one_star_helpful and 'reviews' in one_star_helpful.get('data', {}):
        low_rating_reviews.extend(one_star_helpful['data']['reviews'])
    
    if two_star_helpful and 'reviews' in two_star_helpful.get('data', {}):
        low_rating_reviews.extend(two_star_helpful['data']['reviews'])
    
    # 保存合并后的低分评论
    if low_rating_reviews:
        combined_data = {'data': {'reviews': low_rating_reviews}}
        save_to_json(combined_data, f'combined_low_ratings_{timestamp}.json')
        save_to_csv(low_rating_reviews, f'combined_low_ratings_{timestamp}.csv')
    
    print("数据收集完成！")

if __name__ == "__main__":
    process_reviews()