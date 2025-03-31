#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
import jieba
import jieba.analyse
from wordcloud import WordCloud
import re

# 设置中文字体，需要根据您的系统调整
plt.rcParams['font.sans-serif'] = ['Arial Unicode MS']  # macOS
plt.rcParams['axes.unicode_minus'] = False

# 创建保存分析结果的目录
output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'analysis_results')
os.makedirs(output_dir, exist_ok=True)

def load_reviews(json_file):
    """从JSON文件加载评论数据"""
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    reviews = []
    if 'data' in data and 'reviews' in data['data']:
        for item in data['data']['reviews']:
            if 'value' in item:
                reviews.append(item['value'])
    
    return reviews

def extract_keywords(text, topK=20):
    """使用jieba提取文本关键词"""
    # 移除非中文字符
    text = re.sub(r'[^\u4e00-\u9fa5]', ' ', text)
    # 提取关键词
    keywords = jieba.analyse.extract_tags(text, topK=topK, withWeight=True)
    return keywords

def analyze_reviews(reviews):
    """分析评论数据"""
    # 将评论转换为DataFrame
    df = pd.DataFrame(reviews)
    
    # 基本统计
    total_reviews = len(df)
    rating_counts = df['rating'].value_counts().sort_index()
    
    # 提取所有评论文本
    all_reviews_text = ' '.join(df['review'].fillna(''))
    
    # 提取关键词
    keywords = extract_keywords(all_reviews_text, topK=50)
    
    # 生成词云
    wordcloud_data = {word: weight for word, weight in keywords}
    wordcloud = WordCloud(
        font_path='/System/Library/Fonts/PingFang.ttc',  # macOS中文字体
        width=800, 
        height=400, 
        background_color='white'
    ).generate_from_frequencies(wordcloud_data)
    
    # 保存词云图
    plt.figure(figsize=(10, 5))
    plt.imshow(wordcloud, interpolation='bilinear')
    plt.axis('off')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'keywords_wordcloud.png'), dpi=300)
    
    # 关键词频率条形图
    plt.figure(figsize=(12, 8))
    words, weights = zip(*keywords[:20])
    plt.barh(range(len(words)), weights, align='center')
    plt.yticks(range(len(words)), words)
    plt.xlabel('权重')
    plt.title('评论关键词Top20')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'keywords_bar.png'), dpi=300)
    
    # 评分分布饼图
    plt.figure(figsize=(8, 8))
    plt.pie(rating_counts, labels=rating_counts.index, autopct='%1.1f%%', startangle=90)
    plt.axis('equal')
    plt.title('评分分布')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'rating_distribution.png'), dpi=300)
    
    # 生成分析报告
    report = f"""
    # Moji辞书评论分析报告

    ## 基本统计
    - 总评论数: {total_reviews}
    - 评分分布: {dict(rating_counts)}

    ## 关键词分析
    以下是评论中出现的主要关键词及其权重:
    
    | 关键词 | 权重 |
    |--------|------|
    {chr(10).join([f"| {word} | {weight:.4f} |" for word, weight in keywords[:20]])}
    
    ## 问题分类
    根据关键词分析，用户反馈的主要问题可能集中在以下几个方面:
    
    1. [需要根据实际关键词填写]
    2. [需要根据实际关键词填写]
    3. [需要根据实际关键词填写]
    
    ## 建议
    基于上述分析，建议在MVP阶段重点关注以下功能:
    
    1. [需要根据实际分析填写]
    2. [需要根据实际分析填写]
    3. [需要根据实际分析填写]
    """
    
    # 保存分析报告
    with open(os.path.join(output_dir, 'analysis_report.md'), 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"分析完成，结果已保存到 {output_dir}")
    
    return {
        'total_reviews': total_reviews,
        'rating_counts': rating_counts,
        'keywords': keywords
    }

def main():
    """主函数"""
    # 查找最新的合并低分评论文件
    review_data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'review_data')
    json_files = [f for f in os.listdir(review_data_dir) if f.startswith('combined_low_ratings_') and f.endswith('.json')]
    
    if not json_files:
        print("未找到评论数据文件，请先运行collect_reviews.py收集数据")
        return
    
    # 选择最新的文件
    latest_file = max(json_files)
    json_path = os.path.join(review_data_dir, latest_file)
    
    print(f"正在分析文件: {json_path}")
    reviews = load_reviews(json_path)
    
    if reviews:
        analyze_reviews(reviews)
    else:
        print("未找到有效的评论数据")

if __name__ == "__main__":
    main()