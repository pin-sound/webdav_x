import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// 页面跳转动画类型
enum PageTransitionType {
  /// 共享轴变换 - 水平方向
  sharedAxisHorizontal,

  /// 共享轴变换 - 垂直方向
  sharedAxisVertical,

  /// 淡入淡出缩放
  fadeThrough,

  /// 容器变换
  fade,
}

/// 使用animations包的页面跳转工具类
class PageTransitions {
  /// 使用共享轴变换进行页面跳转（水平方向）
  static Route<T> sharedAxisHorizontal<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  /// 使用共享轴变换进行页面跳转（垂直方向）
  static Route<T> sharedAxisVertical<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
    );
  }

  /// 使用淡入淡出变换进行页面跳转 (优雅、现代)
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }

  /// 使用缩放变换进行页面跳转
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeScaleTransition(animation: animation, child: child);
      },
    );
  }

  /// 共享轴变换 - 缩放 (Z轴)
  static Route<T> sharedAxisScaled<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }

  /// 滑动变换 (类似 iOS)
  static Route<T> slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// 默认页面跳转（使用滑动变换）
  static Route<T> defaultTransition<T>(Widget page) {
    return slide<T>(page);
  }
}

/// 便捷的导航扩展方法
extension NavigationExtensions on BuildContext {
  /// 使用默认动画推送新页面
  Future<T?> pushWithDefault<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.defaultTransition<T>(page));
  }

  /// 使用共享轴水平动画推送新页面
  Future<T?> pushWithSharedAxis<T>(Widget page) {
    return Navigator.push<T>(
      this,
      PageTransitions.sharedAxisHorizontal<T>(page),
    );
  }

  /// 使用淡入淡出动画推送新页面
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.fadeThrough<T>(page));
  }

  /// 使用缩放动画推送新页面
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.scale<T>(page));
  }

  /// 使用共享轴缩放动画推送新页面
  Future<T?> pushWithSharedAxisScaled<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.sharedAxisScaled<T>(page));
  }

  /// 使用滑动动画推送新页面
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.slide<T>(page));
  }
}
