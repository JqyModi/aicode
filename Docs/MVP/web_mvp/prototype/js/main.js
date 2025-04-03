document.addEventListener('DOMContentLoaded', function() {
    // 闪卡翻转功能
    const flipButtons = document.querySelectorAll('.control-button.flip');
    flipButtons.forEach(button => {
        button.addEventListener('click', function() {
            const flashcardFront = this.closest('.flashcard-container').querySelector('.flashcard-front');
            const flashcardBack = this.closest('.flashcard-container').querySelector('.flashcard-back');
            
            if (flashcardFront.classList.contains('active')) {
                flashcardFront.style.transform = 'rotateY(180deg)';
                flashcardBack.style.transform = 'rotateY(0deg)';
                flashcardFront.classList.remove('active');
                flashcardBack.classList.add('active');
            } else {
                flashcardFront.style.transform = 'rotateY(0deg)';
                flashcardBack.style.transform = 'rotateY(180deg)';
                flashcardFront.classList.add('active');
                flashcardBack.classList.remove('active');
            }
        });
    });
    
    // 学习中心菜单展开/收起
    const learningCenter = document.querySelector('.learning-center');
    if (learningCenter) {
        learningCenter.addEventListener('click', function() {
            const menuItems = document.querySelector('.learning-menu-items');
            if (menuItems) {
                menuItems.classList.toggle('active');
                this.classList.toggle('active');
                
                if (this.classList.contains('active')) {
                    this.innerHTML = '<i class="fas fa-times"></i>';
                } else {
                    this.innerHTML = '<i class="fas fa-graduation-cap"></i>';
                }
            }
        });
    }
    
    // 收藏功能
    const favoriteButtons = document.querySelectorAll('.favorite-button, .control-button.favorite');
    favoriteButtons.forEach(button => {
        button.addEventListener('click', function() {
            const icon = this.querySelector('i');
            if (icon.classList.contains('far')) {
                icon.classList.remove('far');
                icon.classList.add('fas');
                icon.style.color = '#FF6B6B';
            } else {
                icon.classList.remove('fas');
                icon.classList.add('far');
                icon.style.color = '';
            }
        });
    });
    
    // 发音按钮动效
    const soundButtons = document.querySelectorAll('.sound-button, .sound-button-list, .sound-button-small, .sound-button-large, .control-button.sound');
    soundButtons.forEach(button => {
        button.addEventListener('click', function() {
            const icon = this.querySelector('i');
            icon.classList.add('pulse-animation');
            
            setTimeout(() => {
                icon.classList.remove('pulse-animation');
            }, 1000);
        });
    });
    
    // 记忆评估按钮
    const memoryButtons = document.querySelectorAll('.memory-button');
    memoryButtons.forEach(button => {
        button.addEventListener('click', function() {
            // 移除其他按钮的选中状态
            memoryButtons.forEach(btn => {
                btn.classList.remove('selected');
            });
            
            // 添加当前按钮的选中状态
            this.classList.add('selected');
            
            // 这里可以添加实际的记忆评估逻辑
            setTimeout(() => {
                // 模拟加载下一个单词
                const flashcardContainer = this.closest('.flashcard-container');
                flashcardContainer.style.opacity = '0.5';
                
                setTimeout(() => {
                    flashcardContainer.style.opacity = '1';
                    
                    // 确保卡片显示正面
                    const flashcardFront = flashcardContainer.querySelector('.flashcard-front');
                    const flashcardBack = flashcardContainer.querySelector('.flashcard-back');
                    
                    flashcardFront.style.transform = 'rotateY(0deg)';
                    flashcardBack.style.transform = 'rotateY(180deg)';
                    flashcardFront.classList.add('active');
                    flashcardBack.classList.remove('active');
                    
                    // 更新进度指示器
                    const activeDot = document.querySelector('.progress-dot.active');
                    if (activeDot && activeDot.nextElementSibling) {
                        activeDot.classList.remove('active');
                        activeDot.classList.add('completed');
                        activeDot.nextElementSibling.classList.add('active');
                    }
                }, 300);
            }, 500);
        });
    });
    
    // 深色模式切换
    const darkModeToggle = document.querySelector('.settings-item input[type="checkbox"]');
    if (darkModeToggle) {
        darkModeToggle.addEventListener('change', function() {
            document.body.classList.toggle('dark-mode');
            
            // 获取所有 iPhone 框架
            const iPhoneFrames = document.querySelectorAll('.iphone-frame');
            iPhoneFrames.forEach(frame => {
                if (this.checked) {
                    frame.style.borderColor = '#000000';
                } else {
                    frame.style.borderColor = '#121212';
                }
            });
        });
    }
    
    // 添加视差效果
    const cards = document.querySelectorAll('.dynamic-card');
    cards.forEach(card => {
        card.addEventListener('mousemove', function(e) {
            const rect = this.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            
            const deltaX = (x - centerX) / centerX;
            const deltaY = (y - centerY) / centerY;
            
            this.style.transform = `perspective(1000px) rotateX(${deltaY * -3}deg) rotateY(${deltaX * 3}deg) translateZ(10px)`;
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) translateZ(0)';
        });
    });
});