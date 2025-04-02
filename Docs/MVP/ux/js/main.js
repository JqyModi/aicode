// 日语学习APP交互功能
document.addEventListener('DOMContentLoaded', function() {
    // 初始化流动导航控制器
    initFlowNavigation();
    
    // 初始化搜索功能
    initSearch();
    
    // 初始化闪卡学习功能
    initFlashcards();
    
    // 初始化收藏功能
    initFavorites();
    
    // 初始化设置页面交互
    initSettings();
});

// 流动导航控制器功能
function initFlowNavigation() {
    const navButton = document.querySelector('.nav-button');
    const navCenterButton = document.querySelector('.nav-center-button');
    
    if (navButton) {
        navButton.addEventListener('click', function() {
            // 模拟导航展开效果
            document.querySelector('.home-screen').classList.add('blur-bg');
            document.querySelector('.flow-nav-expanded').classList.add('fade-in');
            document.querySelector('.flow-nav-expanded').style.display = 'flex';
        });
    }
    
    if (navCenterButton) {
        navCenterButton.addEventListener('click', function() {
            // 模拟导航收起效果
            document.querySelector('.home-screen').classList.remove('blur-bg');
            document.querySelector('.flow-nav-expanded').style.display = 'none';
        });
    }
    
    // 导航菜单项点击事件
    const navMenuItems = document.querySelectorAll('.nav-menu-item');
    navMenuItems.forEach(item => {
        item.addEventListener('click', function() {
            // 这里可以根据点击的菜单项执行相应的导航操作
            const itemLabel = this.querySelector('.nav-item-label').textContent;
            console.log(`导航到: ${itemLabel}`);
            
            // 收起导航菜单
            document.querySelector('.home-screen').classList.remove('blur-bg');
            document.querySelector('.flow-nav-expanded').style.display = 'none';
        });
    });
}

// 搜索功能
function initSearch() {
    const searchInputs = document.querySelectorAll('.search-input, .search-input-active, .search-input-small');
    
    searchInputs.forEach(input => {
        if (input) {
            // 输入事件
            input.addEventListener('input', function() {
                console.log(`搜索: ${this.value}`);
                // 这里可以实现实时搜索建议功能
            });
            
            // 聚焦事件
            input.addEventListener('focus', function() {
                this.parentElement.classList.add('active');
            });
            
            // 失焦事件
            input.addEventListener('blur', function() {
                this.parentElement.classList.remove('active');
            });
        }
    });
    
    // 搜索清除按钮
    const clearButtons = document.querySelectorAll('.fa-times-circle');
    clearButtons.forEach(button => {
        if (button) {
            button.addEventListener('click', function() {
                const input = this.parentElement.querySelector('input');
                input.value = '';
                input.focus();
            });
        }
    });
    
    // 搜索结果项点击事件
    const searchResultItems = document.querySelectorAll('.search-result-item');
    searchResultItems.forEach(item => {
        item.addEventListener('click', function() {
            // 模拟点击搜索结果跳转到词典详情页
            console.log('跳转到词典详情页');
            
            // 移除其他项的选中状态
            searchResultItems.forEach(i => i.classList.remove('active'));
            
            // 添加当前项的选中状态
            this.classList.add('active');
        });
    });
}

// 闪卡学习功能
function initFlashcards() {
    const flipButton = document.querySelector('.control-button.flip');
    const flashcardFront = document.querySelector('.flashcard-front');
    const flashcardBack = document.querySelector('.flashcard-back');
    
    if (flipButton && flashcardFront && flashcardBack) {
        // 翻转闪卡
        flipButton.addEventListener('click', function() {
            if (flashcardFront.classList.contains('active')) {
                // 翻转到背面
                flashcardFront.style.transform = 'rotateY(180deg)';
                flashcardBack.style.transform = 'rotateY(0deg)';
                flashcardFront.classList.remove('active');
                flashcardBack.classList.add('active');
            } else {
                // 翻转到正面
                flashcardFront.style.transform = 'rotateY(0deg)';
                flashcardBack.style.transform = 'rotateY(180deg)';
                flashcardFront.classList.add('active');
                flashcardBack.classList.remove('active');
            }
        });
    }
    
    // 记忆评估按钮
    const memoryButtons = document.querySelectorAll('.memory-button');
    memoryButtons.forEach(button => {
        button.addEventListener('click', function() {
            const difficulty = this.classList.contains('hard') ? '困难' : 
                              this.classList.contains('medium') ? '一般' : '简单';
            
            console.log(`记忆评估: ${difficulty}`);
            
            // 模拟进入下一张闪卡
            if (flashcardFront && flashcardBack) {
                // 重置闪卡到正面
                flashcardFront.style.transform = 'rotateY(0deg)';
                flashcardBack.style.transform = 'rotateY(180deg)';
                flashcardFront.classList.add('active');
                flashcardBack.classList.remove('active');
                
                // 更新进度指示器
                updateProgressIndicator();
            }
        });
    });
    
    // 声音按钮
    const soundButtons = document.querySelectorAll('.sound-button, .sound-button-small, .sound-button-list');
    soundButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.stopPropagation(); // 防止事件冒泡
            console.log('播放发音');
            
            // 添加播放动画
            this.classList.add('pulse');
            setTimeout(() => {
                this.classList.remove('pulse');
            }, 1000);
        });
    });
}

// 更新闪卡进度指示器
function updateProgressIndicator() {
    const progressDots = document.querySelectorAll('.progress-dot');
    if (progressDots.length === 0) return;
    
    // 找到当前活动的点
    let activeIndex = -1;
    for (let i = 0; i < progressDots.length; i++) {
        if (progressDots[i].classList.contains('active')) {
            activeIndex = i;
            break;
        }
    }
    
    // 如果找到活动点，并且不是最后一个
    if (activeIndex >= 0 && activeIndex < progressDots.length - 1) {
        // 将当前活动点标记为已完成
        progressDots[activeIndex].classList.remove('active');
        progressDots[activeIndex].classList.add('completed');
        
        // 将下一个点标记为活动
        progressDots[activeIndex + 1].classList.add('active');
    } else if (activeIndex === progressDots.length - 1) {
        // 如果是最后一个点，模拟完成学习
        console.log('闪卡学习完成');
        
        // 重置所有点
        progressDots.forEach((dot, index) => {
            dot.classList.remove('active', 'completed');
            if (index === 0) dot.classList.add('active');
        });
    }
}

// 收藏功能
function initFavorites() {
    const favoriteButtons = document.querySelectorAll('.control-button.favorite, .favorite-button');
    
    favoriteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.stopPropagation(); // 防止事件冒泡
            
            const icon = this.querySelector('i');
            if (icon.classList.contains('far')) {
                // 添加收藏
                icon.classList.remove('far');
                icon.classList.add('fas');
                console.log('添加到收藏');
            } else {
                // 取消收藏
                icon.classList.remove('fas');
                icon.classList.add('far');
                console.log('从收藏中移除');
            }
        });
    });
    
    // 收藏夹点击事件
    const collectionCards = document.querySelectorAll('.collection-card');
    collectionCards.forEach(card => {
        card.addEventListener('click', function() {
            console.log(`打开收藏夹: ${this.querySelector('.collection-title').textContent}`);
        });
    });
}

// 设置页面交互
function initSettings() {
    // 切换开关
    const switches = document.querySelectorAll('.switch input');
    
    switches.forEach(switchInput => {
        switchInput.addEventListener('change', function() {
            const settingName = this.closest('.settings-item').querySelector('.settings-item-text').textContent;
            console.log(`${settingName} 设置已${this.checked ? '开启' : '关闭'}`);
        });
    });
    
    // 设置项点击
    const settingsItems = document.querySelectorAll('.settings-item');
    settingsItems.forEach(item => {
        // 排除带开关的设置项
        if (!item.querySelector('.switch')) {
            item.addEventListener('click', function() {
                const settingName = this.querySelector('.settings-item-text').textContent;
                console.log(`点击设置项: ${settingName}`);
            });
        }
    });
}

// 返回按钮功能
document.querySelectorAll('.back-button, .back-button-search').forEach(button => {
    button.addEventListener('click', function() {
        console.log('返回上一页');
        // 这里可以实现返回上一页的功能
    });
});

// 添加按钮功能
document.querySelectorAll('.add-button').forEach(button => {
    button.addEventListener('click', function() {
        console.log('添加新项目');
        // 这里可以实现添加新项目的功能
    });
});

// 更多按钮功能
document.querySelectorAll('.more-button').forEach(button => {
    button.addEventListener('click', function(e) {
        e.stopPropagation(); // 防止事件冒泡
        console.log('显示更多选项');
        // 这里可以实现显示更多选项的功能
    });
});

// 实现流动性和连贯性的滚动效果
function initSmoothScrolling() {
    const contentElements = document.querySelectorAll('.screen-content');
    
    contentElements.forEach(content => {
        content.addEventListener('scroll', function() {
            // 滚动时的视差效果
            const scrollTop = this.scrollTop;
            const greetingSection = this.querySelector('.greeting-section');
            
            if (greetingSection) {
                // 滚动时标题缩小效果
                if (scrollTop > 0) {
                    greetingSection.style.transform = `scale(${1 - scrollTop * 0.001})`;
                    greetingSection.style.opacity = 1 - scrollTop * 0.005;
                } else {
                    greetingSection.style.transform = 'scale(1)';
                    greetingSection.style.opacity = 1;
                }
            }
            
            // 滚动时卡片的动态加载效果
            const cards = this.querySelectorAll('.daily-card, .word-card, .collection-item');
            cards.forEach((card, index) => {
                const cardPosition = card.getBoundingClientRect().top;
                const screenPosition = window.innerHeight;
                
                if (cardPosition < screenPosition) {
                    // 卡片进入视口时添加动画
                    setTimeout(() => {
                        card.classList.add('slide-up');
                    }, index * 50); // 错开时间，创造连贯的动画效果
                }
            });
        });
    });
}

// 初始化滚动效果
initSmoothScrolling();

// 实现主页面的动态效果
function initHomePageDynamics() {
    // 动态问候语
    updateGreeting();
    
    // 学习卡片的动态效果
    const learningCards = document.querySelector('.learning-cards');
    if (learningCards) {
        // 初始加载动画
        const cards = learningCards.querySelectorAll('.daily-card, .word-card, .collection-item');
        cards.forEach((card, index) => {
            setTimeout(() => {
                card.classList.add('slide-up');
            }, 300 + index * 100);
        });
    }
}

// 更新问候语
function updateGreeting() {
    const greetingText = document.querySelector('.greeting-text h3');
    if (greetingText) {
        const hour = new Date().getHours();
        let greeting = '';
        
        if (hour >= 5 && hour < 12) {
            greeting = 'おはようございます';
        } else if (hour >= 12 && hour < 18) {
            greeting = 'こんにちは';
        } else {
            greeting = 'こんばんは';
        }
        
        greetingText.textContent = `${greeting}、ユーザー`;
    }
}

// 初始化主页动态效果
initHomePageDynamics();